import SwiftUI

struct RecentView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        Group {
            if appModel.library.documents.isEmpty { emptyState } else { documentList }
        }
        .navigationTitle("最近")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { appModel.push(.scanner) } label: { Image(systemName: "doc.viewfinder") }
                    .accessibilityLabel("扫描文档")
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("还没有最近项目", systemImage: "doc.text.viewfinder")
        } description: {
            Text("扫描文档后会安全地保存在本机。")
        } actions: {
            Button("扫描文档") { appModel.push(.scanner) }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
    }

    private var documentList: some View {
        List(appModel.library.documents) { document in
            Button { appModel.push(.document(document.id)) } label: {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    Image(systemName: "doc.richtext")
                        .font(.title2)
                        .foregroundStyle(DesignTokens.Color.accent)
                        .frame(width: 36)
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                        Text(document.name).font(.body.weight(.medium)).foregroundStyle(.primary).lineLimit(2)
                        Text("\(document.pageCount) 页 · \(document.byteCount.formatted(.byteCount(style: .file)))")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .frame(minHeight: DesignTokens.minimumHitTarget)
        }
        .listStyle(.plain)
    }
}
