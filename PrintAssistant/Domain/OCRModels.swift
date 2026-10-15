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
    let temporaryURL: URL?

    init(
        imageData: Data,
        displayName: String,
        associatedDocumentID: DocumentRecord.ID? = nil,
        temporaryURL: URL? = nil
    ) {
        self.source = .imageData(imageData)
        self.displayName = displayName
        self.associatedDocumentID = associatedDocumentID
        self.temporaryURL = temporaryURL
    }

    init(
        imageFile: URL,
        displayName: String,
        associatedDocumentID: DocumentRecord.ID? = nil,
        temporaryURL: URL? = nil
    ) {
        self.source = .imageFile(imageFile)
        self.displayName = displayName
        self.associatedDocumentID = associatedDocumentID
        self.temporaryURL = temporaryURL
    }

    init(
        pdfURL: URL,
        displayName: String,
        associatedDocumentID: DocumentRecord.ID? = nil,
        temporaryURL: URL? = nil
    ) {
        self.source = .pdfFile(pdfURL)
        self.displayName = displayName
        self.associatedDocumentID = associatedDocumentID
        self.temporaryURL = temporaryURL
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
