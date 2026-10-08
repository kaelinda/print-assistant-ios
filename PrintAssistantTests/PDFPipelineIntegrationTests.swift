import Foundation
import PDFKit
import Testing
import UIKit
@testable import PrintAssistant

/// Exercises the same services used by the user-facing PDF flows with real
/// generated PDF files, Chinese filenames, and a persistent document index.
@MainActor
struct PDFPipelineIntegrationTests {
    @Test
    func stagedPDFsSurviveMergeSplitReorderProtectionAndLibraryRelaunch() async throws {
        let root = FileManager.default.temporaryDirectory
            .appending(path: "PDFPipelineTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        let inputs = root.appending(path: "inputs", directoryHint: .isDirectory)
        let outputs = root.appending(path: "outputs", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: inputs, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: outputs, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let first = inputs.appending(path: "资料一.pdf")
        let second = inputs.appending(path: "合同二.pdf")
        try createPDF(at: first, pageWidths: [100, 120])
        try createPDF(at: second, pageWidths: [140])
        let firstBytes = try Data(contentsOf: first)
        let secondBytes = try Data(contentsOf: second)

        let importer = PDFImportService()
        let staged = try await importer.stage(urls: [first, second])
        defer { importer.cleanup(staged) }
        #expect(staged.map(\.displayName) == ["资料一.pdf", "合同二.pdf"])
        #expect(staged.allSatisfy { $0.isTemporary })
        #expect(staged.allSatisfy { FileManager.default.fileExists(atPath: $0.url.path) })

        let operations = PDFOperationService(outputDirectory: outputs)
        let mergedURL = try await operations.merge(
            urls: staged.map(\.url),
            filename: "合并文件.pdf"
        )
        let merged = try #require(PDFDocument(url: mergedURL))
        #expect(pageWidths(of: merged) == [100, 120, 140])

        let splitURLs = try await operations.split(
            url: mergedURL,
            ranges: [
                .init(startPage: 1, endPage: 1),
                .init(startPage: 2, endPage: 3)
            ],
            filenamePrefix: "拆分文件"
        )
        #expect(splitURLs.count == 2)
        #expect(pageWidths(of: try #require(PDFDocument(url: splitURLs[0]))) == [100])
        #expect(pageWidths(of: try #require(PDFDocument(url: splitURLs[1]))) == [120, 140])

        let rearrangedURL = try await operations.applyPagePlan(
            .init(sourceURL: mergedURL, pageIndexes: [2, 0]),
            filename: "页面调整.pdf"
        )
        #expect(pageWidths(of: try #require(PDFDocument(url: rearrangedURL))) == [140, 100])

        let protection = PDFProtectionService(outputDirectory: outputs)
        let protectedURL = try await protection.protect(
            .init(
                sourceURL: rearrangedURL,
                userPassword: "reader-secret",
                ownerPassword: "owner-secret"
            ),
            filename: "加密文件.pdf"
        )
        #expect(try #require(PDFDocument(url: protectedURL)).isLocked)

        let unlockedURL = try await protection.removeProtection(
            sourceURL: protectedURL,
            password: "reader-secret",
            filename: "最终文件.pdf"
        )
        let unlocked = try #require(PDFDocument(url: unlockedURL))
        #expect(!unlocked.isLocked)
        #expect(pageWidths(of: unlocked) == [140, 100])

        let library = DocumentLibrary(baseURL: root)
        let record = DocumentRecord(
            name: "最终文件.pdf",
            pageCount: unlocked.pageCount,
            byteCount: Int64(try Data(contentsOf: unlockedURL).count),
            source: .generated,
            localURL: unlockedURL
        )
        try library.add(record)

        let relaunched = DocumentLibrary(baseURL: root)
        #expect(relaunched.document(id: record.id)?.localURL == unlockedURL)
        #expect(relaunched.visibleDocuments(query: "最终").map(\.id) == [record.id])

        importer.cleanup(staged)
        #expect(staged.allSatisfy { !FileManager.default.fileExists(atPath: $0.url.path) })
        #expect(try Data(contentsOf: first) == firstBytes)
        #expect(try Data(contentsOf: second) == secondBytes)
        #expect(FileManager.default.fileExists(atPath: unlockedURL.path))
    }

    private func createPDF(at url: URL, pageWidths: [CGFloat]) throws {
        let document = PDFDocument()
        for width in pageWidths {
            let image = UIGraphicsImageRenderer(
                size: CGSize(width: width, height: 200)
            ).image { context in
                UIColor.white.setFill()
                context.cgContext.fill(CGRect(x: 0, y: 0, width: width, height: 200))
            }
            document.insert(try #require(PDFPage(image: image)), at: document.pageCount)
        }
        #expect(document.write(to: url))
    }

    private func pageWidths(of document: PDFDocument) -> [Int] {
        (0..<document.pageCount).compactMap { index in
            document.page(at: index).map {
                Int($0.bounds(for: .mediaBox).width.rounded())
            }
        }
    }
}
