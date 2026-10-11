import Foundation
import PDFKit

struct PDFFileInspection: Equatable, Sendable {
    var pageCount: Int
    var isLocked: Bool

    /// Returns nil when the file is not a readable PDF.
    /// A locked PDF is readable metadata: `isLocked` is true even if `pageCount` is 0.
    static func inspect(url: URL) -> PDFFileInspection? {
        guard let document = PDFDocument(url: url) else { return nil }
        if document.isLocked {
            return PDFFileInspection(pageCount: document.pageCount, isLocked: true)
        }
        guard document.pageCount > 0 else { return nil }
        return PDFFileInspection(pageCount: document.pageCount, isLocked: false)
    }
}
