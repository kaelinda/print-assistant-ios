import Foundation

struct PDFSplitDraft: Hashable, Sendable {
    let source: PDFSourceItem
    let pageCount: Int
    var ranges: [PDFPageRange]

    var isValid: Bool {
        guard pageCount > 0, !ranges.isEmpty else { return false }
        return ranges.allSatisfy {
            $0.startPage >= 1
                && $0.endPage >= $0.startPage
                && $0.endPage <= pageCount
        }
    }
}
