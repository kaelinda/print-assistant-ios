import Foundation
import PDFKit
import Testing
import UIKit
@testable import PrintAssistant

struct PDFOperationServiceTests {
    @Test
    func mergePreservesDocumentAndPageOrderWithoutMutatingSources() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanup() }

        let first = try fixture.makePDF(name: "first.pdf", pageWidths: [100, 120])
        let second = try fixture.makePDF(name: "second.pdf", pageWidths: [140, 160])
        let firstBefore = try Data(contentsOf: first)
        let secondBefore = try Data(contentsOf: second)

        let output = try await fixture.service.merge(
            urls: [first, second],
            filename: "merged.pdf"
        )

        let document = try #require(PDFDocument(url: output))
        #expect(document.pageCount == 4)
        #expect(pageWidths(document) == [100, 120, 140, 160])
        #expect(try Data(contentsOf: first) == firstBefore)
        #expect(try Data(contentsOf: second) == secondBefore)
    }

    @Test
    func splitUsesOneBasedInclusiveRanges() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanup() }

        let source = try fixture.makePDF(
            name: "source.pdf",
            pageWidths: [100, 120, 140, 160]
        )

        let outputs = try await fixture.service.split(
            url: source,
            ranges: [
                .init(startPage: 1, endPage: 2),
                .init(startPage: 3, endPage: 4)
            ],
            filenamePrefix: "part"
        )

        #expect(outputs.count == 2)
        let first = try #require(PDFDocument(url: outputs[0]))
        let second = try #require(PDFDocument(url: outputs[1]))
        #expect(pageWidths(first) == [100, 120])
        #expect(pageWidths(second) == [140, 160])
    }

    @Test
    func pagePlanCanReorderAndDeletePages() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanup() }

        let source = try fixture.makePDF(
            name: "source.pdf",
            pageWidths: [100, 120, 140, 160]
        )

        let output = try await fixture.service.applyPagePlan(
            .init(sourceURL: source, pageIndexes: [3, 0, 2]),
            filename: "managed.pdf"
        )

        let document = try #require(PDFDocument(url: output))
        #expect(document.pageCount == 3)
        #expect(pageWidths(document) == [160, 100, 140])
    }

    @Test
    func rejectsDeletingEveryPage() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanup() }

        let source = try fixture.makePDF(name: "source.pdf", pageWidths: [100])

        await #expect(throws: PDFOperationService.OperationError.self) {
            _ = try await fixture.service.applyPagePlan(
                .init(sourceURL: source, pageIndexes: []),
                filename: "empty.pdf"
            )
        }
    }

    @Test
    func rejectsInvalidSplitRange() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanup() }

        let source = try fixture.makePDF(name: "source.pdf", pageWidths: [100, 120])

        await #expect(throws: PDFOperationService.OperationError.self) {
            _ = try await fixture.service.split(
                url: source,
                ranges: [.init(startPage: 2, endPage: 3)],
                filenamePrefix: "invalid"
            )
        }
    }

    @Test
    func rejectsLockedPDF() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanup() }

        let source = try fixture.makePDF(name: "plain.pdf", pageWidths: [100])
        let document = try #require(PDFDocument(url: source))
        let locked = fixture.root.appending(path: "locked.pdf")
        let options: [PDFDocumentWriteOption: Any] = [
            .userPasswordOption: "secret",
            .ownerPasswordOption: "owner-secret"
        ]
        #expect(document.write(to: locked, withOptions: options))

        await #expect(throws: PDFOperationService.OperationError.self) {
            _ = try await fixture.service.applyPagePlan(
                .init(sourceURL: locked, pageIndexes: [0]),
                filename: "locked-output.pdf"
            )
        }
    }

    @Test
    func rejectsCorruptInput() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanup() }

        let corrupt = fixture.root.appending(path: "corrupt.pdf")
        try Data("not a pdf".utf8).write(to: corrupt)

        await #expect(throws: PDFOperationService.OperationError.self) {
            _ = try await fixture.service.applyPagePlan(
                .init(sourceURL: corrupt, pageIndexes: [0]),
                filename: "output.pdf"
            )
        }
    }

    private func pageWidths(_ document: PDFDocument) -> [Int] {
        (0..<document.pageCount).compactMap { index in
            document.page(at: index).map {
                Int($0.bounds(for: .mediaBox).width.rounded())
            }
        }
    }

    private final class Fixture {
        let root: URL
        let service: PDFOperationService

        init() throws {
            root = FileManager.default.temporaryDirectory
                .appending(path: "PDFOperationTests-\(UUID().uuidString)", directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            service = PDFOperationService(outputDirectory: root)
        }

        func makePDF(name: String, pageWidths: [CGFloat]) throws -> URL {
            let document = PDFDocument()

            for width in pageWidths {
                let image = UIGraphicsImageRenderer(
                    size: CGSize(width: width, height: 200)
                ).image { context in
                    UIColor.white.setFill()
                    context.cgContext.fill(
                        CGRect(x: 0, y: 0, width: width, height: 200)
                    )
                }
                let page = try #require(PDFPage(image: image))
                document.insert(page, at: document.pageCount)
            }

            let url = root.appending(path: name)
            #expect(document.write(to: url))
            return url
        }

        func cleanup() {
            try? FileManager.default.removeItem(at: root)
        }
    }
}
