import SwiftUI

struct SearchView: View {
    @Environment(AppModel.self) private var appModel
    @State private var query = ""
    @State private var recentQueries: [String] = []
    private let recentSearches = RecentSearchStore()

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Text("搜索")
                    .font(.largeTitle.bold())
                    .foregroundStyle(DesignTokens.Color.primaryText)
                    .frame(minHeight: 52, alignment: .leading)

                GlassSearchField(text: $query, prompt: "搜索 PDF、扫描件和 OCR 文字", onSubmit: rememberCurrentQuery)

                if normalizedQuery.isEmpty {
                    emptyQueryContent
                } else if results.isEmpty {
                    noResultsContent
                } else {
                    resultContent
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
        .scrollDismissesKeyboard(.immediately)
        .background(DesignTokens.Color.canvas)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            recentQueries = recentSearches.queries
        }
    }

    private var emptyQueryContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                GlassSectionHeader("最近搜索")
                if !recentQueries.isEmpty {
                    Button("清除") {
                        recentSearches.clear()
                        recentQueries = []
                        appModel.transientMessage = "最近搜索已清除"
                    }
                    .font(.footnote)
                    .foregroundStyle(DesignTokens.Color.accent)
                    .buttonStyle(.plain)
                }
            }

            if recentQueries.isEmpty {
                Text("还没有搜索记录。")
                    .font(.footnote)
                    .foregroundStyle(DesignTokens.Color.secondaryText)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(recentQueries, id: \.self) { item in
                            GlassChip(title: item, isSelected: false) { query = item }
                        }
                    }
                }
                .scrollClipDisabled()
            }

            indexStatusCard

            GlassSectionHeader("建议")
            suggestionCard
        }
    }

    private var indexStatusCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3.weight(.semibold))
                .foregroundStyle(DesignTokens.Color.accent)
                .frame(width: 36, height: 36)
                .background(DesignTokens.Color.cardFill, in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text("本地索引已更新")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(DesignTokens.Color.primaryText)
                Text("\(appModel.library.documents.count) 个文件 · 本地搜索，不上传原文件")
                    .font(.caption)
                    .foregroundStyle(DesignTokens.Color.secondaryText)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .frame(height: 58)
        .background(DesignTokens.Color.stateSurface.opacity(0.72), in: RoundedRectangle(cornerRadius: 18))
    }

    private var suggestionDocuments: [DocumentRecord] {
        Array(appModel.library.documents.prefix(3))
    }

    @ViewBuilder
    private var suggestionCard: some View {
        if suggestionDocuments.isEmpty {
            Text("导入或扫描文件后，会根据资料库给出建议。")
                .font(.footnote)
                .foregroundStyle(DesignTokens.Color.secondaryText)
        } else {
            GlassCard(cornerRadius: 20) {
                VStack(spacing: 0) {
                    ForEach(Array(suggestionDocuments.enumerated()), id: \.element.id) { index, document in
                        suggestionRow(
                            name: document.name,
                            detail: document.hasOCRText ? "OCR 已建立" : "\(document.pageCount) 页",
                            icon: document.hasOCRText ? "person.text.rectangle" : "doc.text"
                        ) {
                            appModel.push(.document(document.id))
                        }
                        if index < suggestionDocuments.count - 1 {
                            Divider().padding(.leading, 64)
                        }
                    }
                }
            }
        }
    }

    private func suggestionRow(name: String, detail: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.body.weight(.medium))
                    .foregroundStyle(DesignTokens.Color.accent)
                    .frame(width: 36, height: 36)
                    .background(DesignTokens.Color.stateSurface, in: RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 3) {
                    Text(name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(DesignTokens.Color.primaryText)
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(DesignTokens.Color.secondaryText)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DesignTokens.Color.tertiaryText)
            }
            .padding(.horizontal, 16)
            .frame(height: 72)
        }
        .buttonStyle(.plain)
    }

    private var noResultsContent: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.title2)
                .foregroundStyle(DesignTokens.Color.accent)
                .frame(minWidth: 64, minHeight: 64)
                .background(DesignTokens.Color.stateSurface, in: RoundedRectangle(cornerRadius: 20))
            Text("没有找到匹配文件")
                .font(.headline)
                .foregroundStyle(DesignTokens.Color.primaryText)
            Text("试试文件名或 OCR 正文中的其他关键词。")
                .font(.footnote)
                .foregroundStyle(DesignTokens.Color.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
    }

    private var resultContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            GlassSectionHeader("搜索结果")
            GlassCard(cornerRadius: 20) {
                VStack(spacing: 0) {
                    ForEach(Array(results.enumerated()), id: \.element.id) { index, document in
                        Button {
                            openResult(document)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "doc.text")
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(DesignTokens.Color.accent)
                                    .frame(width: 36, height: 36)
                                    .background(DesignTokens.Color.stateSurface, in: RoundedRectangle(cornerRadius: 10))
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(document.name)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(DesignTokens.Color.primaryText)
                                    Text(document.searchableText.map { String($0.prefix(28)) } ?? "PDF 文档")
                                        .font(.caption)
                                        .foregroundStyle(DesignTokens.Color.secondaryText)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(DesignTokens.Color.tertiaryText)
                            }
                            .padding(.horizontal, 16)
                            .frame(minHeight: 72)
                        }
                        .buttonStyle(.plain)
                        if index < results.count - 1 { Divider().padding(.leading, 64) }
                    }
                }
            }
        }
    }

    private func rememberCurrentQuery() {
        recentSearches.remember(normalizedQuery)
        recentQueries = recentSearches.queries
    }

    private func openResult(_ document: DocumentRecord) {
        rememberCurrentQuery()
        appModel.push(.document(document.id))
    }

    private var normalizedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var results: [DocumentRecord] {
        appModel.library.visibleDocuments(query: normalizedQuery)
    }
}
