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
    var searchableText: String?

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
        isPasswordProtected: Bool = false,
        searchableText: String? = nil
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
        self.searchableText = searchableText
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case createdAt
        case modifiedAt
        case pageCount
        case byteCount
        case source
        case localURL
        case hasOCRText
        case isPasswordProtected
        case searchableText
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(ID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        modifiedAt = try container.decode(Date.self, forKey: .modifiedAt)
        pageCount = try container.decode(Int.self, forKey: .pageCount)
        byteCount = try container.decode(Int64.self, forKey: .byteCount)
        source = try container.decode(Source.self, forKey: .source)
        hasOCRText = try container.decodeIfPresent(Bool.self, forKey: .hasOCRText) ?? false
        isPasswordProtected = try container.decodeIfPresent(Bool.self, forKey: .isPasswordProtected) ?? false
        searchableText = try container.decodeIfPresent(String.self, forKey: .searchableText)

        let storedPath = try container.decode(String.self, forKey: .localURL)
        if let root = decoder.userInfo[.printAssistantLibraryRoot] as? URL,
           !storedPath.hasPrefix("/"),
           !storedPath.hasPrefix("file:") {
            localURL = LibraryPaths.url(relativePath: storedPath, root: root)
        } else if storedPath.hasPrefix("file:") {
            localURL = URL(string: storedPath) ?? URL(fileURLWithPath: storedPath)
        } else {
            localURL = URL(fileURLWithPath: storedPath)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(modifiedAt, forKey: .modifiedAt)
        try container.encode(pageCount, forKey: .pageCount)
        try container.encode(byteCount, forKey: .byteCount)
        try container.encode(source, forKey: .source)
        try container.encode(hasOCRText, forKey: .hasOCRText)
        try container.encode(isPasswordProtected, forKey: .isPasswordProtected)
        try container.encodeIfPresent(searchableText, forKey: .searchableText)

        if let root = encoder.userInfo[.printAssistantLibraryRoot] as? URL,
           let relative = LibraryPaths.relativePath(for: localURL, root: root) {
            try container.encode(relative, forKey: .localURL)
        } else {
            try container.encode(localURL.absoluteString, forKey: .localURL)
        }
    }
}
