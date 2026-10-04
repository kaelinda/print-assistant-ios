import CoreGraphics
import Foundation

struct IDCopyDraft: Hashable, Sendable {
    enum Side: String, Hashable, Sendable {
        case front
        case back

        var displayName: String {
            switch self {
            case .front: "人像面"
            case .back: "国徽面"
            }
        }
    }

    var frontData: Data?
    var backData: Data?

    var isComplete: Bool {
        frontData != nil && backData != nil
    }
}

enum PhysicalPrintGeometry {
    static let pointsPerInch: CGFloat = 72
    static let millimetersPerInch: CGFloat = 25.4

    static func points(millimeters: CGFloat) -> CGFloat {
        millimeters / millimetersPerInch * pointsPerInch
    }

    static let id1CardSize = CGSize(
        width: points(millimeters: 85.60),
        height: points(millimeters: 53.98)
    )

    static let a4Size = CGSize(width: 595.28, height: 841.89)
}
