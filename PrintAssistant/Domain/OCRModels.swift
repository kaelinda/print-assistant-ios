import Foundation

struct OCRInput: Hashable {
    enum Kind: Hashable {
        case image
        case pdf
    }

    let id = UUID()
    let data: Data
    let kind: Kind
    let displayName: String
}

struct OCRResult: Hashable {
    let id = UUID()
    let text: String
    let sourceName: String
    let pageCount: Int

    var isEmpty: Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
