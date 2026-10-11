import Foundation
import Testing
@testable import PrintAssistant

struct FeedbackMailTests {
    @Test
    func mailtoPercentEncodesSubjectAndBody() {
        let url = FeedbackMail.mailtoURL(body: "a b")
        #expect(
            url?.absoluteString
                == "mailto:?subject=%E6%89%93%E5%8D%B0%E5%8A%A9%E6%89%8B%E5%8F%8D%E9%A6%88&body=a%20b"
        )
    }
}
