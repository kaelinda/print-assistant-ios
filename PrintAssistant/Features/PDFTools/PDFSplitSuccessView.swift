import SwiftUI

struct PDFSplitSuccessView: View {
    @Environment(AppModel.self) private var appModel
    let documentIDs: [DocumentRecord.ID]

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(DesignTokens.Color.success)
                .accessibilityHidden(true)

            VStack(spacing: DesignTokens.Spacing.xs) {
                Text("PDF 已拆分")
                    .font(.title2.bold())
                Text("已生成 \(documents.count) 个新文件")
                    .font(.headline)
                Text("源文件保持不变，新文件已保存在本机。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if !documents.isEmpty {
                VStack(spacing: DesignTokens.Spacing.xs) {
                    ForEach(documents) { document in
                        Button {
                            appModel.push(.document(document.id))
                        } label: {
                            HStack {
                                Image(systemName: "doc")
                                Text(document.name)
                                    .lineLimit(1)
                                Spacer()
                                Text("\(document.pageCount) 页")
                                    .foregroundStyle(.secondary)
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.tertiary)
                            }
                            .frame(minHeight: DesignTokens.minimumHitTarget)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Button("返回文件") {
                appModel.selectedTab = .files
                appModel.popToRoot()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer()
        }
        .padding(DesignTokens.Spacing.lg)
        .navigationTitle("完成")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var documents: [DocumentRecord] {
        documentIDs.compactMap(appModel.library.document(id:))
    }
}
