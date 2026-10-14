import Foundation
import Testing
@testable import PrintAssistant

struct FeedbackMailTests {
    @Test
    func mailtoPercentEncodesSubjectAndBody() throws {
        let absolute = try #require(FeedbackMail.mailtoURL(body: "a b")).absoluteString
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "&+=?")
        let encodedSubject = FeedbackMail.subject.addingPercentEncoding(withAllowedCharacters: allowed)
        #expect(absolute.hasPrefix("mailto:?"))
        #expect(absolute.contains("subject=\(try #require(encodedSubject))"))
        #expect(absolute.contains("body=a%20b"))
        #expect(!absolute.contains(" "))
    }
}
