import PDFKit
import Testing
import UIKit
@testable import PrintAssistant

struct IDCopyPDFTests {
    @Test
    func generatesSingleA4Page() async throws {
        let front = imageData(width: 856, height: 540)
        let back = imageData(width: 856, height: 540)
        let draft = IDCopyDraft(frontData: front, backData: back)

        let url = try await PDFDocumentService().makeIDCopyPDF(
            from: draft,
            filename: "id-copy-\(UUID().uuidString).pdf"
        )
        defer { try? FileManager.default.removeItem(at: url) }

        let document = try #require(PDFDocument(url: url))
        #expect(document.pageCount == 1)

        let page = try #require(document.page(at: 0))
        let bounds = page.bounds(for: .mediaBox)
        #expect(abs(bounds.width - PhysicalPrintGeometry.a4Size.width) < 1)
        #expect(abs(bounds.height - PhysicalPrintGeometry.a4Size.height) < 1)
    }

    @Test
    func rejectsMissingSide() async {
        let draft = IDCopyDraft(
            frontData: imageData(width: 856, height: 540),
            backData: nil
        )

        await #expect(throws: PDFDocumentService.PDFError.self) {
            _ = try await PDFDocumentService().makeIDCopyPDF(
                from: draft,
                filename: "incomplete-\(UUID().uuidString).pdf"
            )
        }
    }

    private func imageData(width: CGFloat, height: CGFloat) -> Data {
        let image = UIGraphicsImageRenderer(size: CGSize(width: width, height: height)).image { context in
            UIColor.white.setFill()
            context.cgContext.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
        return image.jpegData(compressionQuality: 0.95)!
    }
}
