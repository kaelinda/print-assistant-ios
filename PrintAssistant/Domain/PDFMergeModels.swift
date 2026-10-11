import Foundation

struct PDFSourceItem: Identifiable, Hashable, Sendable {
    let id: UUID
    let url: URL
    let displayName: String
    let isTemporary: Bool

    init(
        id: UUID = UUID(),
        url: URL,
        displayName: String,
        isTemporary: Bool = false
    ) {
        self.id = id
        self.url = url
        self.displayName = displayName
        self.isTemporary = isTemporary
    }
}

struct PDFMergeDraft: Hashable, Sendable {
    var sources: [PDFSourceItem]

    var canMerge: Bool {
        sources.count >= 2
    }
}
