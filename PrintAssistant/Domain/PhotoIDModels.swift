import CoreGraphics
import Foundation

struct PhotoIDDraft: Hashable, Sendable {
    var data: Data
    var sizeName: String
    var background: PhotoIDBackground
    /// Normalized crop shift in -1...1. Zero keeps the aspect-fill window centered.
    var cropOffset: CGSize = .zero

    enum PhotoIDBackground: String, CaseIterable, Hashable, Sendable {
        case white
        case blue
        case red

        var displayName: String {
            switch self {
            case .white: String(localized: "白底")
            case .blue: String(localized: "蓝底")
            case .red: String(localized: "红底")
            }
        }
    }
}

enum PhotoIDGeometry {
    struct Spec: Equatable, Sendable {
        var widthMillimeters: CGFloat
        var heightMillimeters: CGFloat
        var columns: Int
        var rows: Int

        var cardSize: CGSize {
            CGSize(
                width: PhysicalPrintGeometry.points(millimeters: widthMillimeters),
                height: PhysicalPrintGeometry.points(millimeters: heightMillimeters)
            )
        }

        var sheetCount: Int { columns * rows }
    }

    static let oneInch = Spec(widthMillimeters: 25, heightMillimeters: 35, columns: 2, rows: 3)
    static let twoInch = Spec(widthMillimeters: 35, heightMillimeters: 49, columns: 2, rows: 2)

    static func spec(for sizeName: String) -> Spec {
        let compact = sizeName.replacingOccurrences(of: " ", with: "")
        if compact.hasPrefix("2") {
            return twoInch
        }
        return oneInch
    }

    static func cardRects(
        for spec: Spec,
        pageSize: CGSize = PhysicalPrintGeometry.a4Size,
        gapMillimeters: CGFloat = 6
    ) -> [CGRect] {
        let cardSize = spec.cardSize
        let gap = PhysicalPrintGeometry.points(millimeters: gapMillimeters)
        let totalWidth = cardSize.width * CGFloat(spec.columns) + gap * CGFloat(spec.columns - 1)
        let totalHeight = cardSize.height * CGFloat(spec.rows) + gap * CGFloat(spec.rows - 1)
        let origin = CGPoint(
            x: (pageSize.width - totalWidth) / 2,
            y: (pageSize.height - totalHeight) / 2
        )

        return (0..<spec.rows).flatMap { row in
            (0..<spec.columns).map { column in
                CGRect(
                    x: origin.x + CGFloat(column) * (cardSize.width + gap),
                    y: origin.y + CGFloat(row) * (cardSize.height + gap),
                    width: cardSize.width,
                    height: cardSize.height
                )
            }
        }
    }

    /// Crop window inside `imageSize` that matches `aspect` and shifts with `offset`.
    /// Each axis of `offset` is clamped to -1...1. Zero is centered.
    static func cropRect(imageSize: CGSize, aspect: CGSize, offset: CGSize) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0, aspect.width > 0, aspect.height > 0 else {
            return .zero
        }

        let imageAspect = imageSize.width / imageSize.height
        let targetAspect = aspect.width / aspect.height
        let cropSize: CGSize
        if imageAspect > targetAspect {
            cropSize = CGSize(width: imageSize.height * targetAspect, height: imageSize.height)
        } else {
            cropSize = CGSize(width: imageSize.width, height: imageSize.width / targetAspect)
        }

        let spareX = max(0, imageSize.width - cropSize.width)
        let spareY = max(0, imageSize.height - cropSize.height)
        let shiftX = min(1, max(-1, offset.width))
        let shiftY = min(1, max(-1, offset.height))
        return CGRect(
            x: (shiftX + 1) / 2 * spareX,
            y: (shiftY + 1) / 2 * spareY,
            width: cropSize.width,
            height: cropSize.height
        )
    }
}
