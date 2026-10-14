import Foundation
import Testing
@testable import PrintAssistant

struct OCRModelsTests {
    @Test
    func emptyResultIgnoresWhitespace() {
        let result = OCRResult(text: "  \n ", sourceName: "sample.jpg", pageCount: 1)
        #expect(result.isEmpty)
    }

    @Test
    func nonEmptyResultIsRecognized() {
        let result = OCRResult(text: "租赁合同", sourceName: "sample.jpg", pageCount: 1)
        #expect(!result.isEmpty)
    }

    @Test
    func pdfInputKeepsAFileURLInsteadOfBytes() {
        let url = URL(fileURLWithPath: "/tmp/sample.pdf")
        let input = OCRInput(pdfURL: url, displayName: "sample.pdf")
        #expect(input.pdfURL == url)
        guard case .pdfFile(let stored) = input.source else {
            Issue.record("PDF 输入应指向文件")
            return
        }
        #expect(stored == url)
    }

    @Test
    func ocrThumbnailLongSideStaysWithinBound() {
        let letter = OCRRecognitionService.thumbnailSize(forPage: CGSize(width: 612, height: 792))
        #expect(abs(max(letter.width, letter.height) - OCRRecognitionService.maxPixelDimension) < 0.01)
        #expect(letter.width < letter.height)

        let huge = OCRRecognitionService.thumbnailSize(forPage: CGSize(width: 5000, height: 2000))
        #expect(abs(max(huge.width, huge.height) - OCRRecognitionService.maxPixelDimension) < 0.01)

        #expect(OCRRecognitionService.thumbnailSize(forPage: .zero) == CGSize(width: 1, height: 1))
    }
}
