import Foundation

struct OCRInput: Hashable, Sendable {
    enum Source: Hashable, Sendable {
        case imageData(Data)
        case imageFile(URL)
        case pdfFile(URL)
    }

    let id = UUID()
    let source: Source
    let displayName: String
    let associatedDocumentID: DocumentRecord.ID?

    init(imageData: Data, displayName: String, associatedDocumentID: DocumentRecord.ID? = nil) {
        self.source = .imageData(imageData)
        self.displayName = displayName
        self.associatedDocumentID = associatedDocumentID
    }

    init(imageFile: URL, displayName: String, associatedDocumentID: DocumentRecord.ID? = nil) {
        self.source = .imageFile(imageFile)
        self.displayName = displayName
        self.associatedDocumentID = associatedDocumentID
    }

    init(pdfURL: URL, displayName: String, associatedDocumentID: DocumentRecord.ID? = nil) {
        self.source = .pdfFile(pdfURL)
        self.displayName = displayName
        self.associatedDocumentID = associatedDocumentID
    }

    var pdfURL: URL? {
        if case .pdfFile(let url) = source { return url }
        return nil
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
