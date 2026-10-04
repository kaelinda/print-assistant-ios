import SwiftUI

struct ToolsView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        List {
            Section("常用") {
                Button {
                    appModel.push(.photoPDFSelection)
                } label: {
                    toolRow(
                        title: "图片转 PDF",
                        subtitle: "选择、排序并按纸张尺寸生成 PDF",
                        systemImage: "photo.on.rectangle.angled"
                    )
                }

                Button {
                    appModel.push(.ocrSource)
                } label: {
                    toolRow(
                        title: "文字识别",
                        subtitle: "从照片、PDF 或相机提取可复制文字",
                        systemImage: "text.viewfinder"
                    )
                }
            }

            Section("证件与打印") {
                Button {
                    appModel.push(.idCopyCapture(.init(), .front))
                } label: {
                    toolRow(
                        title: "身份证复印",
                        subtitle: "正反面采集并按实际尺寸排到 A4",
                        systemImage: "person.text.rectangle"
                    )
                }
            }

            Section("PDF 工具") {
                Button {
                    appModel.push(.pdfSplitSource)
                } label: {
                    toolRow(
                        title: "拆分 PDF",
                        subtitle: "按页码范围生成多个新文件",
                        systemImage: "scissors"
                    )
                }
            }

            Section("即将实现") {
                Label("合并 PDF", systemImage: "doc.on.doc")
                Label("页面管理", systemImage: "rectangle.3.group")
            }
            .foregroundStyle(.secondary)
        }
        .navigationTitle("工具")
    }

    private func toolRow(
        title: String,
        subtitle: String,
        systemImage: String
    ) -> some View {
        Label {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                Text(title)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(DesignTokens.Color.accent)
        }
        .frame(minHeight: DesignTokens.minimumHitTarget)
    }
}
