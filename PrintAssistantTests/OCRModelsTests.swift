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
}
