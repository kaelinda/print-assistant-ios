import Foundation

struct DocumentRecord: Identifiable, Hashable, Codable {
    typealias ID = UUID

    enum Source: String, Codable, Hashable {
        case scan
        case photos
        case files
        case generated
    }

    let id: ID
    var name: String
    var createdAt: Date
    var modifiedAt: Date
    var pageCount: Int
    var byteCount: Int64
    var source: Source
    var localURL: URL
    var hasOCRText: Bool
    var isPasswordProtected: Bool

    init(
        id: ID = UUID(),
        name: String,
        createdAt: Date = .now,
        modifiedAt: Date = .now,
        pageCount: Int,
        byteCount: Int64,
        source: Source,
        localURL: URL,
        hasOCRText: Bool = false,
        isPasswordProtected: Bool = false
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.pageCount = pageCount
        self.byteCount = byteCount
        self.source = source
        self.localURL = localURL
        self.hasOCRText = hasOCRText
        self.isPasswordProtected = isPasswordProtected
    }
}
