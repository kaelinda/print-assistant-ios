import Foundation

enum FeedbackMail {
    static let subject = "打印助手反馈"

    static func mailtoURL(body: String) -> URL? {
        let encodedSubject = percentEncode(subject)
        let encodedBody = percentEncode(body)
        return URL(string: "mailto:?subject=\(encodedSubject)&body=\(encodedBody)")
    }

    private static func percentEncode(_ value: String) -> String {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "&+=?")
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
    }
}
