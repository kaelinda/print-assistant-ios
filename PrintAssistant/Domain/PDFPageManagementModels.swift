import Foundation

struct PDFPageManagementDraft: Hashable, Sendable {
    let source: PDFSourceItem
    let originalPageCount: Int
    var pageIndexes: [Int]

    var canGenerate: Bool {
        !pageIndexes.isEmpty
            && pageIndexes.allSatisfy { $0 >= 0 && $0 < originalPageCount }
    }

    var hasChanges: Bool {
        pageIndexes != Array(0..<originalPageCount)
    }
}
