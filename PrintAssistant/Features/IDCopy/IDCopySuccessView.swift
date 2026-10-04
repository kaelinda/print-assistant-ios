import SwiftUI

struct IDCopySuccessView: View {
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
                        Text("身份证复印件已生成")
                            .font(.title2.bold())
                        Text(document.name)
                            .font(.headline)
                        Text("A4 · 1 页 · 文件已保存在本机")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    PrimaryActionButton(title: "预览 / 打印", state: .enabled) {
                        appModel.push(.pdfPreview(document.id))
                    }

                    ShareLink(item: document.localURL) {
                        Label("分享 PDF", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity, minHeight: 50)
                    }
                    .buttonStyle(.bordered)

                    Button("返回最近") {
                        appModel.selectedTab = .recent
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
