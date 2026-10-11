import Foundation

struct PrintTemplate: Identifiable, Codable, Hashable, Sendable {
    enum Category: String, Codable, CaseIterable, Hashable, Sendable {
        case all
        case id
        case photo
        case document

        var displayName: String {
            switch self {
            case .all: "全部"
            case .id: "证件"
            case .photo: "照片"
            case .document: "文档"
            }
        }
    }

    var id: UUID
    var name: String
    var subtitle: String
    var category: Category
    var paper: String
    var scale: String
    var marginMillimeters: Int
    var copies: Int

    init(
        id: UUID = UUID(),
        name: String,
        subtitle: String,
        category: Category,
        paper: String = "A4",
        scale: String = "100%",
        marginMillimeters: Int = 12,
        copies: Int = 1
    ) {
        self.id = id
        self.name = name
        self.subtitle = subtitle
        self.category = category
        self.paper = paper
        self.scale = scale
        self.marginMillimeters = marginMillimeters
        self.copies = copies
    }

    static let defaults: [PrintTemplate] = [
        .init(name: "身份证复印", subtitle: "A4 · 实际尺寸 · 上下排版", category: .id),
        .init(name: "1寸证件照", subtitle: "A4 · 6 张 · 白底", category: .photo, copies: 6),
        .init(name: "合同打印", subtitle: "A4 · 100% · 12 mm 边距", category: .document)
    ]
}
