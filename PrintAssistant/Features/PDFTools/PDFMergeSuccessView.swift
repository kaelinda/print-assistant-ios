import SwiftUI

struct PDFMergeSuccessView: View {
    @Environment(AppModel.self) private var appModel
    let documentID: DocumentRecord.ID

    var body: some View {
        Group {
            if let document = appModel.library.document(id: documentID) {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    Spacer()

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(DesignTokens.Color.success)
                        .accessibilityHidden(true)

                    VStack(spacing: DesignTokens.Spacing.xs) {
                        Text("PDF 已合并")
                            .font(.title2.bold())
                        Text(document.name)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        Text("\(document.pageCount) 页 · \(document.byteCount.formatted(.byteCount(style: .file)))\n源文件保持不变，新文件已保存在本机。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    PrimaryActionButton(title: "预览 / 打印", state: .enabled) {
                        appModel.push(.pdfPreview(document.id))
                    }

                    ShareLink(item: document.localURL) {
                        Label("分享 PDF", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity, minHeight: 50)
                    }
                    .buttonStyle(.bordered)

                    Button("返回文件") {
                        appModel.selectedTab = .files
                        appModel.popToRoot()
                    }

                    Spacer()
                }
                .padding(DesignTokens.Spacing.lg)
                .navigationTitle("完成")
                .navigationBarTitleDisplayMode(.inline)
            } else {
                ContentUnavailableView("文件不存在", systemImage: "doc.badge.exclamationmark")
            }
        }
    }
}
