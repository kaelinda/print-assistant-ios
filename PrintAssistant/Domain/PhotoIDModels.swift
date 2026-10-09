import Foundation

struct PhotoIDDraft: Hashable, Sendable {
    var data: Data
    var sizeName: String
    var background: PhotoIDBackground

    enum PhotoIDBackground: String, CaseIterable, Hashable, Sendable {
        case white
        case blue
        case red

        var displayName: String {
            switch self {
            case .white: "白底"
            case .blue: "蓝底"
            case .red: "红底"
            }
        }
    }
}
