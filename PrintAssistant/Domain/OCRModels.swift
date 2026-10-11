import Foundation

struct OCRInput: Hashable, Sendable {
    enum Kind: Hashable, Sendable {
        case image
        case pdf
    }

    let id = UUID()
    let data: Data
    let kind: Kind
    let displayName: String
    let associatedDocumentID: DocumentRecord.ID?

    init(data: Data, kind: Kind, displayName: String, associatedDocumentID: DocumentRecord.ID? = nil) {
        self.data = data
        self.kind = kind
        self.displayName = displayName
        self.associatedDocumentID = associatedDocumentID
    }
}

struct OCRResult: Hashable, Sendable {
    let id = UUID()
    let text: String
    let sourceName: String
    let pageCount: Int

    var isEmpty: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
