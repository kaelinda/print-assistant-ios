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
                    appModel.push(.pdfPageSource)
                } label: {
                    toolRow(
                        title: "页面管理",
                        subtitle: "查看、重排或删除 PDF 页面",
                        systemImage: "rectangle.3.group"
                    )
                }

                Button {
                    appModel.push(.pdfSplitSource)
                } label: {
                    toolRow(
                        title: "拆分 PDF",
                        subtitle: "按页码范围生成多个新文件",
                        systemImage: "scissors"
                    )
                }

                Button {
                    appModel.push(.pdfMergeSelection)
                } label: {
                    toolRow(
                        title: "合并 PDF",
                        subtitle: "选择多个 PDF，调整顺序后生成新文件",
                        systemImage: "doc.on.doc"
                    )
                }
                Button {
                    appModel.push(.pdfUtility(.compress))
                } label: {
                    toolRow(
                        title: "压缩 PDF",
                        subtitle: "优化文件体积，保留可编辑文字",
                        systemImage: "arrow.down.doc"
                    )
                }

                Button {
                    appModel.push(.pdfUtility(.protect))
                } label: {
                    toolRow(
                        title: "加密 PDF",
                        subtitle: "设置打开密码，保护文件内容",
                        systemImage: "lock.doc"
                    )
                }

                Button {
                    appModel.push(.pdfUtility(.unlock))
                } label: {
                    toolRow(
                        title: "解除 PDF 密码",
                        subtitle: "使用正确密码生成未加密副本",
                        systemImage: "lock.open"
                    )
                }
            }

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
