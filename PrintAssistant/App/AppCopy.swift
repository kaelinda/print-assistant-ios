import Foundation

/// Counts, measurements, and stored canonical values that need a locale-aware presentation.
enum AppCopy {
    static func pages(_ count: Int) -> String {
        String(localized: "\(count) 页")
    }

    /// Three independent counts, so each noun pluralizes on its own.
    static func batchSummary(succeeded: Int, failed: Int, cancelled: Int) -> String {
        let succeededText = String(localized: "成功 \(succeeded) 个")
        let failedText = String(localized: "失败 \(failed) 个")
        let cancelledText = String(localized: "取消 \(cancelled) 个")
        return "\(succeededText) · \(failedText) · \(cancelledText)"
    }

    /// ISO sizes stay ISO. Letter is a locale name; the stored token is unchanged.
    static func paperName(_ stored: String) -> String {
        switch stored.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() {
        case "LETTER", "US LETTER":
            String(localized: "信纸")
        default:
            stored.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    static func scaleName(_ stored: String) -> String {
        let trimmed = stored.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.contains("实际")
            || trimmed.compare("actual", options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
            || trimmed.compare("actual size", options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame {
            return String(localized: "实际大小")
        }
        return trimmed
    }

    static func margin(_ millimeters: Int) -> String {
        let measurement = Measurement(value: Double(millimeters), unit: UnitLength.millimeters)
        let formatted = measurement.formatted(.measurement(width: .abbreviated, usage: .asProvided))
        return String(localized: "\(formatted) 边距")
    }

    static func copiesLabel(_ count: Int) -> String {
        String(localized: "份数 \(count)")
    }

    static func templateSummary(paper: String, scale: String, marginMillimeters: Int, copies: Int) -> String {
        let paperText = paperName(paper)
        let scaleText = scaleName(scale)
        let marginText = margin(marginMillimeters)
        let copiesText = String(localized: "\(copies) 份")
        return "\(paperText) · \(scaleText) · \(marginText) · \(copiesText)"
    }

    static func printTemplateLine(name: String, paper: String, scale: String, copies: Int) -> String {
        let title = templateTitle(name)
        let paperText = paperName(paper)
        let scaleText = scaleName(scale)
        let copiesText = String(localized: "\(copies) 份")
        return String(localized: "打印模板：\(title) · \(paperText) · \(scaleText) · \(copiesText)")
    }

    /// Known built-in names localize. Custom names stay as the user saved them.
    static func templateTitle(_ name: String) -> String {
        switch name {
        case "身份证复印": String(localized: "身份证复印")
        case "1寸证件照": String(localized: "1寸证件照")
        case "合同打印": String(localized: "合同打印")
        default: name
        }
    }

    static func templateSubtitle(_ subtitle: String) -> String {
        switch subtitle {
        case "A4 · 实际尺寸 · 上下排版": String(localized: "A4 · 实际尺寸 · 上下排版")
        case "A4 · 6 张 · 白底": String(localized: "A4 · 6 张 · 白底")
        case "A4 · 100% · 12 mm 边距": String(localized: "A4 · 100% · 12 mm 边距")
        default: subtitle
        }
    }

    static func templateBadge(_ category: PrintTemplate.Category) -> String {
        switch category {
        case .all: String(localized: "全部")
        case .id: String(localized: "证件")
        case .photo: String(localized: "1 寸")
        case .document:
            String(localized: LocalizedStringResource("badge.document", defaultValue: "文档"))
        }
    }

    static var id1CardSize: String {
        let style = Measurement<UnitLength>.FormatStyle(width: .abbreviated, usage: .asProvided)
            .precision(.fractionLength(2))
        let width = Measurement(value: 85.60, unit: UnitLength.millimeters).formatted(style)
        let height = Measurement(value: 53.98, unit: UnitLength.millimeters).formatted(style)
        return "\(width) × \(height)"
    }

    static func datedPDF(_ prefix: String) -> String {
        "\(prefix)-\(Int(Date.now.timeIntervalSince1970)).pdf"
    }
}
