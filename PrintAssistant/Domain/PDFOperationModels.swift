import Foundation

struct PDFPageRange: Hashable, Sendable {
    let startPage: Int
    let endPage: Int

    init(startPage: Int, endPage: Int) {
        self.startPage = startPage
        self.endPage = endPage
    }

    var pageCount: Int {
        max(0, endPage - startPage + 1)
    }
}

struct PDFPagePlan: Hashable, Sendable {
    let sourceURL: URL
    var pageIndexes: [Int]

    init(sourceURL: URL, pageIndexes: [Int]) {
        self.sourceURL = sourceURL
        self.pageIndexes = pageIndexes
    }
}
