import PDFKit
import Testing
import UIKit
@testable import PrintAssistant

struct PhotoPDFGenerationTests {
    @Test
    func generatesOneA4PagePerPhoto() async throws {
        let first = pngData(width: 400, height: 300)
        let second = pngData(width: 300, height: 400)
        let draft = PhotoPDFDraft(
            items: [
                .init(data: first, displayName: "1.png"),
                .init(data: second, displayName: "2.png")
            ],
            paper: .a4,
            fitMode: .fit,
            marginPoints: 34
        )

        let filename = "photo-test-\(UUID().uuidString).pdf"
        let url = try await PDFDocumentService().makePhotoPDF(from: draft, filename: filename)
        defer { try? FileManager.default.removeItem(at: url) }

        let document = try #require(PDFDocument(url: url))
        #expect(document.pageCount == 2)

        let firstPage = try #require(document.page(at: 0))
        let bounds = firstPage.bounds(for: .mediaBox)
        #expect(abs(bounds.width - PhotoPDFDraft.Paper.a4.sizeInPoints.width) < 1)
        #expect(abs(bounds.height - PhotoPDFDraft.Paper.a4.sizeInPoints.height) < 1)
    }

    private func pngData(width: CGFloat, height: CGFloat) -> Data {
        let image = UIGraphicsImageRenderer(size: CGSize(width: width, height: height)).image { context in
            UIColor.white.setFill()
            context.cgContext.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
        return image.pngData()!
    }
}
