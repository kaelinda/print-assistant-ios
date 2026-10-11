import Foundation

struct PDFProtectionRequest: Sendable {
    let sourceURL: URL
    let userPassword: String
    let ownerPassword: String

    var isValid: Bool {
        !userPassword.isEmpty && !ownerPassword.isEmpty
    }
}
