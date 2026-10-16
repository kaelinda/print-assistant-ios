import CoreGraphics
import Foundation

enum IDCopyWatermarkLayout {
    static let defaultText = String(localized: "此证件仅用于 xxxx")
    static let maxLength = 40
    static let fontSize: CGFloat = 24
    static let opacity: CGFloat = 0.18
    static let angleDegrees: Double = -18
    static let columnSpacing: CGFloat = 240
    static let rowSpacing: CGFloat = 170

    static func normalized(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return String(trimmed.prefix(maxLength))
    }
}

struct IDCopyDraft: Hashable, Sendable {
    enum Side: String, Hashable, Sendable {
        case front
        case back

        var displayName: String {
            switch self {
            case .front: String(localized: "人像面")
            case .back: String(localized: "国徽面")
            }
        }

        var captureHeading: String {
            switch self {
            case .front: String(localized: "拍摄身份证人像面")
            case .back: String(localized: "拍摄身份证国徽面")
            }
        }

        var captureButtonTitle: String {
            switch self {
            case .front: String(localized: "拍摄人像面")
            case .back: String(localized: "拍摄国徽面")
            }
        }

        var reviewHeading: String {
            switch self {
            case .front: String(localized: "检查人像面")
            case .back: String(localized: "检查国徽面")
            }
        }

        var reviewAccessibilityLabel: String {
            switch self {
            case .front: String(localized: "身份证人像面拍摄结果")
            case .back: String(localized: "身份证国徽面拍摄结果")
            }
        }
    }

    var frontData: Data?
    var backData: Data?
    var watermarkText: String = IDCopyWatermarkLayout.defaultText

    var normalizedWatermarkText: String? {
        IDCopyWatermarkLayout.normalized(watermarkText)
    }

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
