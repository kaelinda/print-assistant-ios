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
            case .unreadablePDF: "PDF 文件无法读取或已经损坏。"
            case .alreadyLocked: "PDF 已经受密码保护。"
            case .notLocked: "PDF 当前没有密码保护。"
            case .invalidPassword: "密码不正确。"
            case .emptyPassword: "密码不能为空。"
            case .outputConflictsWithSource: "输出文件不能覆盖源 PDF。"
            case .unableToWrite: "无法写入受保护的 PDF。"
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
        let directory = outputDirectory

        return try await Task.detached(priority: .userInitiated) {
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
                throw ProtectionError.unableToWrite
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
        }.value
    }

    func removeProtection(
        sourceURL: URL,
        password: String,
        filename: String
    ) async throws -> URL {
        guard !password.isEmpty else { throw ProtectionError.emptyPassword }
        let directory = outputDirectory

        return try await Task.detached(priority: .userInitiated) {
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
                guard let original = document.page(at: pageIndex),
                      let copy = original.copy() as? PDFPage else {
                    throw ProtectionError.unableToWrite
                }
                unprotected.insert(copy, at: pageIndex)
            }
            guard unprotected.write(to: url) else {
                throw ProtectionError.unableToWrite
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
        }.value
    }

    private static func outputURL(
        filename: String,
        directory: URL?,
        protectedInput: URL
    ) throws -> URL {
        let root: URL
        if let directory {
            root = directory
        } else {
            let base = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            root = base.appending(path: "Documents", directoryHint: .isDirectory)
        }

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
