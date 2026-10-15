import SwiftUI

enum ToolGroup: String, CaseIterable, Codable, Hashable {
    case documents
    case printAndID = "print-and-id"
    case morePDF = "more-pdf"

    var title: String {
        switch self {
        case .documents: "文档"
        case .printAndID: "打印与证件"
        case .morePDF: "更多 PDF"
        }
    }
}

enum ToolID: String, CaseIterable, Codable, Hashable {
    case pdfTools
    case batchProcessing
    case compressPDF
    case protectPDF
    case unlockPDF
    case ocr
    case idTools
    case photoPDF
    case photoID
    case printTemplates
    case mergePDF
    case splitPDF
}

struct ToolCatalogEntry {
    let id: ToolID
    let group: ToolGroup
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    let route: AppModel.Route
}

enum ToolCatalog {
    static let defaultOrder: [ToolGroup: [ToolID]] = [
        .documents: [
            .pdfTools,
            .batchProcessing,
            .compressPDF,
            .protectPDF,
            .unlockPDF,
            .ocr
        ],
        .printAndID: [
            .idTools,
            .photoPDF,
            .photoID,
            .printTemplates
        ],
        .morePDF: [
            .mergePDF,
            .splitPDF
        ]
    ]

    private static let entries: [ToolID: ToolCatalogEntry] = [
        .pdfTools: ToolCatalogEntry(
            id: .pdfTools,
            group: .documents,
            title: "PDF 工具箱",
            subtitle: "合并、拆分、提取页面",
            systemImage: "doc.on.doc",
            tint: DesignTokens.Color.accent,
            route: .pdfPageSource
        ),
        .batchProcessing: ToolCatalogEntry(
            id: .batchProcessing,
            group: .documents,
            title: "批量处理",
            subtitle: "一次处理多个文件",
            systemImage: "square.stack.3d.up",
            tint: DesignTokens.Color.warning,
            route: .batchSelection
        ),
        .compressPDF: ToolCatalogEntry(
            id: .compressPDF,
            group: .documents,
            title: "压缩 PDF",
            subtitle: "减小文件体积，保留页面",
            systemImage: "doc.zipper",
            tint: DesignTokens.Color.accent,
            route: .pdfUtility(.compress, nil)
        ),
        .protectPDF: ToolCatalogEntry(
            id: .protectPDF,
            group: .documents,
            title: "保护 PDF",
            subtitle: "设置密码，生成受保护副本",
            systemImage: "lock.doc",
            tint: DesignTokens.Color.warning,
            route: .pdfUtility(.protect, nil)
        ),
        .unlockPDF: ToolCatalogEntry(
            id: .unlockPDF,
            group: .documents,
            title: "解除 PDF 密码",
            subtitle: "使用正确密码生成未加密副本",
            systemImage: "lock.open",
            tint: DesignTokens.Color.warning,
            route: .pdfUtility(.unlock, nil)
        ),
        .ocr: ToolCatalogEntry(
            id: .ocr,
            group: .documents,
            title: "文字识别",
            subtitle: "从图片或 PDF 提取文字",
            systemImage: "text.viewfinder",
            tint: DesignTokens.Color.success,
            route: .ocrSource
        ),
        .idTools: ToolCatalogEntry(
            id: .idTools,
            group: .printAndID,
            title: "证件工具",
            subtitle: "身份证复印、证件照排版",
            systemImage: "person.text.rectangle",
            tint: DesignTokens.Color.warning,
            route: .idToolHub
        ),
        .photoPDF: ToolCatalogEntry(
            id: .photoPDF,
            group: .printAndID,
            title: "图片转 PDF",
            subtitle: "图片自动适配纸张",
            systemImage: "photo.on.rectangle.angled",
            tint: DesignTokens.Color.accent,
            route: .photoPDFSelection
        ),
        .photoID: ToolCatalogEntry(
            id: .photoID,
            group: .printAndID,
            title: "证件照排版",
            subtitle: "1 寸照片排版到 A4",
            systemImage: "person.crop.rectangle",
            tint: DesignTokens.Color.warning,
            route: .photoIDSource
        ),
        .printTemplates: ToolCatalogEntry(
            id: .printTemplates,
            group: .printAndID,
            title: "打印模板",
            subtitle: "保存常用纸张与边距",
            systemImage: "printer",
            tint: DesignTokens.Color.success,
            route: .templateCenter
        ),
        .mergePDF: ToolCatalogEntry(
            id: .mergePDF,
            group: .morePDF,
            title: "合并 PDF",
            subtitle: "按顺序合并多个文件",
            systemImage: "arrow.triangle.merge",
            tint: DesignTokens.Color.accent,
            route: .pdfMergeSelection
        ),
        .splitPDF: ToolCatalogEntry(
            id: .splitPDF,
            group: .morePDF,
            title: "拆分 PDF",
            subtitle: "按页码范围拆出新文件",
            systemImage: "arrow.triangle.branch",
            tint: DesignTokens.Color.accent,
            route: .pdfSplitSource
        )
    ]

    static func entry(for id: ToolID) -> ToolCatalogEntry {
        guard let entry = entries[id] else {
            preconditionFailure("Missing tool catalog entry for \(id.rawValue)")
        }
        return entry
    }

    static func group(for id: ToolID) -> ToolGroup {
        entry(for: id).group
    }
}
