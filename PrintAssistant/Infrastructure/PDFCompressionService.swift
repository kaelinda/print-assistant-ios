import Foundation
import PDFKit

struct PDFCompressionService: Sendable {
    enum CompressionError: LocalizedError, Equatable {
        case unreadablePDF
        case lockedPDF
        case outputConflictsWithSource
        case unableToWrite
        case noMeaningfulSavings

        var errorDescription: String? {
            switch self {
            case .unreadablePDF: "PDF 文件无法读取或已经损坏。"
            case .lockedPDF: "受密码保护的 PDF 需要先解锁。"
            case .outputConflictsWithSource: "输出文件不能覆盖源 PDF。"
            case .unableToWrite: "无法写入压缩后的 PDF。"
            case .noMeaningfulSavings: "这个 PDF 已经比较紧凑，没有可观的压缩空间。"
            }
        }
    }

    struct Result: Sendable, Equatable {
        let url: URL
        let originalBytes: Int64
        let compressedBytes: Int64

        var savedBytes: Int64 {
            max(0, originalBytes - compressedBytes)
        }

        var savedFraction: Double {
            guard originalBytes > 0 else { return 0 }
            return Double(savedBytes) / Double(originalBytes)
        }
    }

    private let outputDirectory: URL?

    init(outputDirectory: URL? = nil) {
        self.outputDirectory = outputDirectory
    }

    func compress(sourceURL: URL, filename: String) async throws -> Result {
        let directory = outputDirectory

        return try await Task.detached(priority: .userInitiated) {
            guard let document = PDFDocument(url: sourceURL), document.pageCount > 0 else {
                throw CompressionError.unreadablePDF
            }
            guard !document.isLocked else {
                throw CompressionError.lockedPDF
            }

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
            guard output.standardizedFileURL.path != sourceURL.standardizedFileURL.path else {
                throw CompressionError.outputConflictsWithSource
            }

            let sourceValues = try sourceURL.resourceValues(forKeys: [.fileSizeKey])
            let originalBytes = Int64(sourceValues.fileSize ?? 0)

            let options: [PDFDocumentWriteOption: Any] = [
                .optimizeImagesForScreenOption: true,
                .saveImagesAsJPEGOption: true
            ]

            guard document.write(to: output, withOptions: options) else {
                throw CompressionError.unableToWrite
            }

            guard
                let verification = PDFDocument(url: output),
                !verification.isLocked,
                verification.pageCount == document.pageCount
            else {
                try? FileManager.default.removeItem(at: output)
                throw CompressionError.unableToWrite
            }

            let outputValues = try output.resourceValues(forKeys: [.fileSizeKey])
            let compressedBytes = Int64(outputValues.fileSize ?? 0)

            guard compressedBytes > 0, compressedBytes < originalBytes else {
                try? FileManager.default.removeItem(at: output)
                throw CompressionError.noMeaningfulSavings
            }

            do {
                try FileManager.default.setAttributes(
                    [.protectionKey: FileProtectionType.complete],
                    ofItemAtPath: output.path
                )
            } catch {
                try? FileManager.default.removeItem(at: output)
                throw CompressionError.unableToWrite
            }

            return Result(
                url: output,
                originalBytes: originalBytes,
                compressedBytes: compressedBytes
            )
        }.value
    }
}
