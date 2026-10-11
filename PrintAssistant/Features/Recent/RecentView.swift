import SwiftUI

struct RecentView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                HStack {
                    Text("最近")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(DesignTokens.Color.primaryText)

                    Spacer()

                    Button { appModel.push(.scanner) } label: {
                        Image(systemName: "doc.viewfinder")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(DesignTokens.Color.primaryText)
                            .frame(width: 46, height: 46)
                    }
                    .buttonStyle(.plain)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay { Circle().stroke(.white.opacity(0.78), lineWidth: 1) }
                    .shadow(color: Color(red: 20 / 255, green: 26 / 255, blue: 41 / 255).opacity(0.13), radius: 15, y: 10)
                    .accessibilityLabel("扫描文档")
                }
                .frame(height: 52)

                Button {
                    appModel.selectedTab = .search
                    appModel.popToRoot()
                } label: {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(DesignTokens.Color.primaryText)
                        Text("搜索文档与扫描文字")
                            .font(.system(size: 13))
                            .foregroundStyle(DesignTokens.Color.secondaryText)
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 48)
                }
                .buttonStyle(.plain)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay { Capsule().stroke(.white.opacity(0.78), lineWidth: 1) }
                .shadow(color: Color(red: 20 / 255, green: 26 / 255, blue: 41 / 255).opacity(0.13), radius: 15, y: 10)
                .accessibilityLabel("搜索文档与扫描文字")

                Color.clear.frame(height: 74)

                if appModel.library.documents.isEmpty {
                    emptyState
                } else {
                    documentList
                }
            }
            .padding(.horizontal, 24)
        }
        .background(DesignTokens.Color.canvas)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 40, weight: .medium))
                .foregroundStyle(DesignTokens.Color.accent)
                .frame(width: 88, height: 88)
                .background(DesignTokens.Color.stateSurface, in: RoundedRectangle(cornerRadius: 28))

            Text("还没有最近项目")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(DesignTokens.Color.primaryText)
                .frame(maxWidth: .infinity)

            Text("扫描、导入或把图片整理成 PDF 后，会显示在这里。")
                .font(.system(size: 12))
                .foregroundStyle(DesignTokens.Color.secondaryText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            Color.clear.frame(height: 4)

            Button("扫描文档") { appModel.push(.scanner) }
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 216, height: 52)
                .background(DesignTokens.Color.accent.opacity(0.95), in: Capsule())
                .overlay { Capsule().stroke(.white.opacity(0.32), lineWidth: 1) }

            Button("导入文件") {
                appModel.transientMessage = "导入文件功能即将支持"
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(DesignTokens.Color.primaryText)
            .frame(width: 216, height: 52)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay { Capsule().stroke(.white.opacity(0.72), lineWidth: 1) }
            .shadow(color: Color(red: 20 / 255, green: 26 / 255, blue: 41 / 255).opacity(0.08), radius: 9, y: 6)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 370)
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
