import SwiftUI

struct FilesView: View {
    @Environment(AppModel.self) private var appModel

    @State private var sort: DocumentLibrary.Sort = .modified
    @State private var source: DocumentLibrary.SourceFilter = .all
    @State private var query = ""

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                titleRow
                GlassSearchField(text: $query, prompt: "搜索文件")
                filterRow

                if let error = appModel.library.persistenceError, appModel.library.documents.isEmpty {
                    emptyCard(title: "无法读取文件库", message: error, icon: "exclamationmark.triangle")
                } else if visibleDocuments.isEmpty {
                    emptyCard(
                        title: source == .all ? "还没有文件" : "没有符合条件的文件",
                        message: source == .all ? "扫描或生成 PDF 后会出现在这里。" : "可以切换到其他来源查看文件。",
                        icon: "folder"
                    )
                } else {
                    groupedDocumentList
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
        .scrollDismissesKeyboard(.immediately)
        .background(DesignTokens.Color.canvas)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var titleRow: some View {
        HStack {
            Text("文件")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(DesignTokens.Color.primaryText)
            Spacer()
            GlassIconButton {
                appModel.push(.scanner)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 21, weight: .medium))
                    .foregroundStyle(DesignTokens.Color.primaryText)
            }
            .accessibilityLabel("添加文件")
        }
        .frame(height: 52)
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                GlassChip(title: "最近", isSelected: source == .all) { source = .all }
                GlassChip(title: "PDF", isSelected: source == .generated) { source = .generated }
                GlassChip(title: "扫描件", isSelected: source == .scan) { source = .scan }
                GlassChip(title: "图片", isSelected: source == .photos) { source = .photos }
            }
        }
        .scrollClipDisabled()
    }

    private var groupedDocumentList: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(groups, id: \.title) { group in
                GlassSectionHeader(group.title)
                    .padding(.top, 4)

                GlassCard(cornerRadius: 20) {
                    VStack(spacing: 0) {
                        ForEach(Array(group.documents.enumerated()), id: \.element.id) { index, document in
                            Button {
                                appModel.push(.document(document.id))
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: document.source == .photos ? "photo" : "doc.text")
                                        .font(.system(size: 17, weight: .medium))
                                        .foregroundStyle(DesignTokens.Color.accent)
                                        .frame(width: 36, height: 36)
                                        .background(DesignTokens.Color.stateSurface, in: RoundedRectangle(cornerRadius: 10))
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(document.name)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundStyle(DesignTokens.Color.primaryText)
                                            .lineLimit(1)
                                        Text("\(document.pageCount) 页 · \(document.byteCount.formatted(.byteCount(style: .file)))")
                                            .font(.system(size: 11))
                                            .foregroundStyle(DesignTokens.Color.secondaryText)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(DesignTokens.Color.tertiaryText)
                                }
                                .padding(.horizontal, 16)
                                .frame(height: 72)
                                .contentShape(.rect)
                            }
                            .buttonStyle(.plain)

                            if index < group.documents.count - 1 {
                                Divider().padding(.leading, 64)
                            }
                        }
                    }
                }
            }
        }
    }

    private func emptyCard(title: String, message: String, icon: String) -> some View {
        GlassCard(cornerRadius: 22) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(DesignTokens.Color.accent)
                    .frame(width: 64, height: 64)
                    .background(DesignTokens.Color.stateSurface, in: RoundedRectangle(cornerRadius: 20))
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(DesignTokens.Color.primaryText)
                Text(message)
                    .font(.system(size: 12))
                    .foregroundStyle(DesignTokens.Color.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 34)
        }
    }

    private var visibleDocuments: [DocumentRecord] {
        appModel.library.visibleDocuments(sort: sort, source: source, query: query)
    }

    private var groups: [(title: String, documents: [DocumentRecord])] {
        let calendar = Calendar.current
        let today = visibleDocuments.filter { calendar.isDateInToday($0.modifiedAt) }
        let yesterday = visibleDocuments.filter { calendar.isDateInYesterday($0.modifiedAt) }
        let earlier = visibleDocuments.filter {
            !calendar.isDateInToday($0.modifiedAt) && !calendar.isDateInYesterday($0.modifiedAt)
        }
        return [("今天", today), ("昨天", yesterday), ("更早", earlier)].filter { !$0.documents.isEmpty }
    }
}
