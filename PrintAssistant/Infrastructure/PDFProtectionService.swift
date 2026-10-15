import Foundation
import PDFKit

struct PDFProtectionService: Sendable {
    enum ProtectionError: LocalizedError, Equatable {
        case unreadablePDF
        case alreadyLocked
        case notLocked
        case invalidPassword
        case emptyPassword
        case outputConflictsWithSource
        case unableToWrite

        var errorDescription: String? {
            switch self {
            case .unreadablePDF: String(localized: "PDF 文件无法读取或已经损坏。")
            case .alreadyLocked: String(localized: "PDF 已经受密码保护。")
            case .notLocked: String(localized: "PDF 当前没有密码保护。")
            case .invalidPassword: String(localized: "密码不正确。")
            case .emptyPassword: String(localized: "密码不能为空。")
            case .outputConflictsWithSource: String(localized: "输出文件不能覆盖源 PDF。")
            case .unableToWrite: String(localized: "无法写入受保护的 PDF。")
            }
        }
    }

    private let outputDirectory: URL?

    init(outputDirectory: URL? = nil) {
        self.outputDirectory = outputDirectory
    }

    func protect(
        _ request: PDFProtectionRequest,
        filename: String
    ) async throws -> URL {
        guard request.isValid else { throw ProtectionError.emptyPassword }
        try Task.checkCancellation()
        let directory = outputDirectory

        let task = Task.detached(priority: .userInitiated) {
            try Task.checkCancellation()
            guard let document = PDFDocument(url: request.sourceURL), document.pageCount > 0 else {
                throw ProtectionError.unreadablePDF
            }
            guard !document.isLocked else {
                throw ProtectionError.alreadyLocked
            }

            let url = try Self.outputURL(
                filename: filename,
                directory: directory,
                protectedInput: request.sourceURL
            )

            let options: [PDFDocumentWriteOption: Any] = [
                .userPasswordOption: request.userPassword,
                .ownerPasswordOption: request.ownerPassword
            ]

            guard document.write(to: url, withOptions: options) else {
                try? FileManager.default.removeItem(at: url)
                throw ProtectionError.unableToWrite
            }

            do {
                try Task.checkCancellation()
            } catch {
                try? FileManager.default.removeItem(at: url)
                throw error
            }

            guard
                let verification = PDFDocument(url: url),
                verification.isLocked,
                verification.unlock(withPassword: request.userPassword),
                verification.pageCount == document.pageCount
            else {
                try? FileManager.default.removeItem(at: url)
                throw ProtectionError.unableToWrite
            }

            try Self.protectAtRest(url)
            return url
        }
        return try await withTaskCancellationHandler {
            try await task.value
        } onCancel: {
            task.cancel()
        }
    }

    func removeProtection(
        sourceURL: URL,
        password: String,
        filename: String
    ) async throws -> URL {
        guard !password.isEmpty else { throw ProtectionError.emptyPassword }
        try Task.checkCancellation()
        let directory = outputDirectory

        let task = Task.detached(priority: .userInitiated) {
            try Task.checkCancellation()
            guard let document = PDFDocument(url: sourceURL), document.pageCount > 0 else {
                throw ProtectionError.unreadablePDF
            }
            guard document.isLocked else {
                throw ProtectionError.notLocked
            }
            guard document.unlock(withPassword: password) else {
                throw ProtectionError.invalidPassword
            }

            let url = try Self.outputURL(
                filename: filename,
                directory: directory,
                protectedInput: sourceURL
            )

            // Rebuild the pages into a fresh document: PDFKit can retain
            // encryption settings when an unlocked document is written directly.
            let unprotected = PDFDocument()
            for pageIndex in 0..<document.pageCount {
                try Task.checkCancellation()
                guard let original = document.page(at: pageIndex),
                      let copy = original.copy() as? PDFPage else {
                    throw ProtectionError.unableToWrite
                }
                unprotected.insert(copy, at: pageIndex)
            }
            guard unprotected.write(to: url) else {
                try? FileManager.default.removeItem(at: url)
                throw ProtectionError.unableToWrite
            }

            do {
                try Task.checkCancellation()
            } catch {
                try? FileManager.default.removeItem(at: url)
                throw error
            }

            guard
                let verification = PDFDocument(url: url),
                !verification.isLocked,
                verification.pageCount == document.pageCount
            else {
                try? FileManager.default.removeItem(at: url)
                throw ProtectionError.unableToWrite
            }

            try Self.protectAtRest(url)
            return url
        }
        return try await withTaskCancellationHandler {
            try await task.value
        } onCancel: {
            task.cancel()
        }
    }

    private static func outputURL(
        filename: String,
        directory: URL?,
        protectedInput: URL
    ) throws -> URL {
        let root = directory ?? LibraryPaths.filesDirectory()

        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let output = root.appending(path: filename, directoryHint: .notDirectory)

        guard output.standardizedFileURL.path != protectedInput.standardizedFileURL.path else {
            throw ProtectionError.outputConflictsWithSource
        }
        return output
    }

    private static func protectAtRest(_ url: URL) throws {
        do {
            try FileManager.default.setAttributes(
                [.protectionKey: FileProtectionType.complete],
                ofItemAtPath: url.path
            )
        } catch {
            try? FileManager.default.removeItem(at: url)
            throw ProtectionError.unableToWrite
        }
    }
}
