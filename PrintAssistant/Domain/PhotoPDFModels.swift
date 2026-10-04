import Foundation

struct PhotoPDFItem: Identifiable, Hashable, Sendable {
    let id: UUID
    let data: Data
    let displayName: String

    init(id: UUID = UUID(), data: Data, displayName: String) {
        self.id = id
        self.data = data
        self.displayName = displayName
    }
}

struct PhotoPDFDraft: Hashable, Sendable {
    enum Paper: String, CaseIterable, Hashable, Sendable {
        case a4
        case letter

        var displayName: String {
            switch self {
            case .a4: "A4"
            case .letter: "Letter"
            }
        }

        var sizeInPoints: CGSize {
            switch self {
            case .a4: CGSize(width: 595.28, height: 841.89)
            case .letter: CGSize(width: 612, height: 792)
            }
        }
    }

    enum FitMode: String, CaseIterable, Hashable, Sendable {
        case fit
        case fill

        var displayName: String {
            switch self {
            case .fit: "完整显示"
            case .fill: "填满页面"
            }
        }
    }

    var items: [PhotoPDFItem]
    var paper: Paper = .a4
    var fitMode: FitMode = .fit
    var marginPoints: CGFloat = 34
}
