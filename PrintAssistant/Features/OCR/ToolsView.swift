import SwiftUI

struct ToolsView: View {
    @Environment(AppModel.self) private var appModel

    private struct ToolDefinition {
        let title: String
        let subtitle: String
        let systemImage: String
        let tint: SwiftUI.Color
        let action: () -> Void
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("工具")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(DesignTokens.Color.primaryText)
                    Spacer()
                    GlassIconButton {
                        appModel.transientMessage = "更多工具设置即将支持"
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(DesignTokens.Color.primaryText)
                    }
                    .accessibilityLabel("更多工具")
                }
                .frame(height: 52)

                toolSection(title: "文档", rows: [
                    ToolDefinition(title: "PDF 工具箱", subtitle: "合并、拆分、压缩、提取页面", systemImage: "doc.on.doc", tint: DesignTokens.Color.accent) { appModel.push(.pdfPageSource) },
                    ToolDefinition(title: "批量处理", subtitle: "一次处理多个文件", systemImage: "square.stack.3d.up", tint: DesignTokens.Color.warning) { appModel.transientMessage = "批量处理功能即将支持" },
                    ToolDefinition(title: "文字识别", subtitle: "从图片或 PDF 提取文字", systemImage: "text.viewfinder", tint: DesignTokens.Color.success) { appModel.push(.ocrSource) }
                ])

                toolSection(title: "打印与证件", rows: [
                    ToolDefinition(title: "证件工具", subtitle: "身份证复印、证件照排版", systemImage: "person.text.rectangle", tint: DesignTokens.Color.warning) { appModel.push(.idCopyCapture(.init(), .front)) },
                    ToolDefinition(title: "图片转 PDF", subtitle: "图片自动适配纸张", systemImage: "photo.on.rectangle.angled", tint: DesignTokens.Color.accent) { appModel.push(.photoPDFSelection) },
                    ToolDefinition(title: "打印模板", subtitle: "保存常用纸张与边距", systemImage: "printer", tint: DesignTokens.Color.success) { appModel.transientMessage = "打印模板功能即将支持" }
                ])
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
        .background(DesignTokens.Color.canvas)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func toolSection(
        title: String,
        rows: [ToolDefinition]
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            GlassSectionHeader(title)
            GlassCard(cornerRadius: 20) {
                VStack(spacing: 0) {
                    ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                        GlassActionRow(
                            title: row.title,
                            subtitle: row.subtitle,
                            systemImage: row.systemImage,
                            tint: row.tint,
                            action: row.action
                        )
                        if index < rows.count - 1 {
                            Divider().padding(.leading, 70)
                        }
                    }
                }
            }
        }
    }
}
