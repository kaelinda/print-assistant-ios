import PDFKit
import Testing
import UIKit
@testable import PrintAssistant

struct PDFDocumentServiceTests {
    @Test
    func createsPDFWithExpectedPageCount() throws {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 420)).image { context in
            UIColor.white.setFill()
            context.cgContext.fill(CGRect(x: 0, y: 0, width: 300, height: 420))
        }

        let url = try PDFDocumentService().makePDF(
            from: [image, image],
            filename: "test-\(UUID().uuidString).pdf"
        )

        #expect(FileManager.default.fileExists(atPath: url.path()))
        let document = PDFDocument(url: url)
        #expect(document?.pageCount == 2)

        try? FileManager.default.removeItem(at: url)
    }
}
