import CoreGraphics
import Foundation

struct PrintLayout: Equatable, Sendable {
    enum Scale: Equatable, Sendable {
        /// Fraction of an aspect-fit into the margin box. `1` fills the box on one side.
        case fit(CGFloat)
        case actualSize
    }

    static let a4 = CGSize(width: 595.2, height: 841.8)
    static let a3 = CGSize(width: 841.8, height: 1190.6)
    static let a5 = CGSize(width: 419.5, height: 595.2)
    static let letter = CGSize(width: 612, height: 792)

    var paperSize: CGSize
    var scale: Scale
    var marginPoints: CGFloat
    var copies: Int

    init(template: PrintTemplate) {
        paperSize = Self.paperSize(named: template.paper)
        scale = Self.parseScale(template.scale)
        marginPoints = Self.points(millimeters: CGFloat(max(0, template.marginMillimeters)))
        copies = Self.normalizedCopies(template.copies)
    }

    static func paperSize(named name: String) -> CGSize {
        switch name.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() {
        case "A3": a3
        case "A5": a5
        case "LETTER", "US LETTER": letter
        default: a4
        }
    }

    static func parseScale(_ text: String) -> Scale {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.contains("实际") || trimmed.lowercased() == "actual" {
            return .actualSize
        }
        let number = trimmed.replacingOccurrences(of: "%", with: "")
        let value = Double(number) ?? 100
        let factor = CGFloat(value / 100)
        guard factor.isFinite, factor > 0 else { return .fit(1) }
        return .fit(min(factor, 4))
    }

    static func normalizedCopies(_ copies: Int) -> Int {
        min(99, max(1, copies))
    }

    static func points(millimeters: CGFloat) -> CGFloat {
        millimeters / 25.4 * 72
    }

    static func destinationRect(
        pageSize: CGSize,
        paperSize: CGSize,
        marginPoints: CGFloat,
        scale: Scale
    ) -> CGRect {
        let paper = CGRect(origin: .zero, size: paperSize)
        let inset = max(0, marginPoints)
        var printable = paper.insetBy(dx: inset, dy: inset)
        if printable.width <= 1 || printable.height <= 1 {
            printable = paper
        }
        guard pageSize.width > 0, pageSize.height > 0 else { return printable }

        let fitted = aspectFit(pageSize, in: printable)
        let target: CGSize
        switch scale {
        case .fit(let factor):
            let clamped = min(max(factor, 0.05), 4)
            target = CGSize(width: fitted.width * clamped, height: fitted.height * clamped)
        case .actualSize:
            target = pageSize
        }
        return CGRect(
            x: printable.midX - target.width / 2,
            y: printable.midY - target.height / 2,
            width: target.width,
            height: target.height
        )
    }

    private static func aspectFit(_ size: CGSize, in container: CGRect) -> CGSize {
        let widthScale = container.width / size.width
        let heightScale = container.height / size.height
        let scale = min(widthScale, heightScale)
        return CGSize(width: size.width * scale, height: size.height * scale)
    }
}
