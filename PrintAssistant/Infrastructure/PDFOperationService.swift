import Foundation
import PDFKit

struct PDFOperationService: Sendable {
    enum OperationError: LocalizedError, Equatable {
        case insufficientInputs
        case unreadablePDF
        case lockedPDF
        case invalidRange
        case invalidPageSelection
        case emptyOutput
        case unableToCopyPage
        case unableToWrite

        var errorDescription: String? {
            switch self {
            case .insufficientInputs: "至少需要两个 PDF 文件。"
            case .unreadablePDF: "PDF 文件无法读取或已经损坏。"
            case .lockedPDF: "PDF 已受密码保护，当前无法处理。"
            case .invalidRange: "拆分页码范围无效。"
            case .invalidPageSelection: "页面选择包含不存在的页码。"
            case .emptyOutput: "操作后不能生成空 PDF。"
            case .unableToCopyPage: "无法复制 PDF 页面。"
            case .unableToWrite: "无法写入 PDF 结果。"
            }
        }
    }

    private let outputDirectory: URL?

    init(outputDirectory: URL? = nil) {
        self.outputDirectory = outputDirectory
    }

    func merge(urls: [URL], filename: String) async throws -> URL {
        guard urls.count >= 2 else { throw OperationError.insufficientInputs }
        let directory = outputDirectory

        return try await Task.detached(priority: .userInitiated) {
            let output = PDFDocument()
            var insertionIndex = 0

            for url in urls {
                let source = try Self.open(url)
                for pageIndex in 0..<source.pageCount {
                    let page = try Self.copyPage(from: source, index: pageIndex)
                    output.insert(page, at: insertionIndex)
                    insertionIndex += 1
                }
            }

            guard insertionIndex > 0 else { throw OperationError.emptyOutput }
            return try Self.writeVerified(
                output,
                expectedPageCount: insertionIndex,
                filename: filename,
                directory: directory
            )
        }.value
    }

    func split(
        url: URL,
        ranges: [PDFPageRange],
        filenamePrefix: String
    ) async throws -> [URL] {
        guard !ranges.isEmpty else { throw OperationError.invalidRange }
        let directory = outputDirectory

        return try await Task.detached(priority: .userInitiated) {
            let source = try Self.open(url)
            let validated = try ranges.map { range -> ClosedRange<Int> in
                guard
                    range.startPage >= 1,
                    range.endPage >= range.startPage,
                    range.endPage <= source.pageCount
                else {
                    throw OperationError.invalidRange
                }
                return (range.startPage - 1)...(range.endPage - 1)
            }

            var outputs: [URL] = []
            do {
                for (index, range) in validated.enumerated() {
                    let document = PDFDocument()
                    for pageIndex in range {
                        document.insert(
                            try Self.copyPage(from: source, index: pageIndex),
                            at: document.pageCount
                        )
                    }

                    let url = try Self.writeVerified(
                        document,
                        expectedPageCount: range.count,
                        filename: "\(filenamePrefix)-\(index + 1).pdf",
                        directory: directory
                    )
                    outputs.append(url)
                }
                return outputs
            } catch {
                for output in outputs {
                    try? FileManager.default.removeItem(at: output)
                }
                throw error
            }
        }.value
    }

    func applyPagePlan(_ plan: PDFPagePlan, filename: String) async throws -> URL {
        guard !plan.pageIndexes.isEmpty else { throw OperationError.emptyOutput }
        let directory = outputDirectory

        return try await Task.detached(priority: .userInitiated) {
            let source = try Self.open(plan.sourceURL)

            guard plan.pageIndexes.allSatisfy({ $0 >= 0 && $0 < source.pageCount }) else {
                throw OperationError.invalidPageSelection
            }

            let output = PDFDocument()
            for index in plan.pageIndexes {
                output.insert(
                    try Self.copyPage(from: source, index: index),
                    at: output.pageCount
                )
            }

            return try Self.writeVerified(
                output,
                expectedPageCount: plan.pageIndexes.count,
                filename: filename,
                directory: directory
            )
        }.value
    }

    private static func open(_ url: URL) throws -> PDFDocument {
        guard let document = PDFDocument(url: url), document.pageCount > 0 else {
            throw OperationError.unreadablePDF
        }
        guard !document.isLocked else {
            throw OperationError.lockedPDF
        }
        return document
    }

    private static func copyPage(from document: PDFDocument, index: Int) throws -> PDFPage {
        guard
            let page = document.page(at: index),
            let copy = page.copy() as? PDFPage
        else {
            throw OperationError.unableToCopyPage
        }
        return copy
    }

    private static func writeVerified(
        _ document: PDFDocument,
        expectedPageCount: Int,
        filename: String,
        directory: URL?
    ) throws -> URL {
        guard expectedPageCount > 0 else { throw OperationError.emptyOutput }

        let root = try directory ?? defaultOutputDirectory()
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let url = root.appending(path: filename, directoryHint: .notDirectory)

        guard document.write(to: url) else {
            throw OperationError.unableToWrite
        }

        guard
            let verification = PDFDocument(url: url),
            !verification.isLocked,
            verification.pageCount == expectedPageCount
        else {
            try? FileManager.default.removeItem(at: url)
            throw OperationError.unableToWrite
        }

        do {
            try FileManager.default.setAttributes(
                [.protectionKey: FileProtectionType.complete],
                ofItemAtPath: url.path()
            )
        } catch {
            try? FileManager.default.removeItem(at: url)
            throw OperationError.unableToWrite
        }

        return url
    }

    private static func defaultOutputDirectory() throws -> URL {
        let base = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return base.appending(path: "Documents", directoryHint: .isDirectory)
    }
}
