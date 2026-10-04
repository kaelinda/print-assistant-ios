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
