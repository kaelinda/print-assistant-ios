import SwiftUI

struct SearchView: View {
    @Environment(AppModel.self) private var appModel
    @State private var query = ""

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Text("搜索")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(DesignTokens.Color.primaryText)
                    .frame(height: 52, alignment: .leading)

                GlassSearchField(text: $query, prompt: "搜索 PDF、扫描件和 OCR 文字")

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
    }

    private var emptyQueryContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                GlassSectionHeader("最近搜索")
                Button("清除") {
                    appModel.transientMessage = "最近搜索已清除"
                }
                .font(.system(size: 12))
                .foregroundStyle(DesignTokens.Color.accent)
                .buttonStyle(.plain)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(["租赁合同", "身份证", "报销"], id: \.self) { item in
                        GlassChip(title: item, isSelected: false) { query = item }
                    }
                }
            }
            .scrollClipDisabled()

            indexStatusCard

            GlassSectionHeader("建议")
            suggestionCard
        }
    }

    private var indexStatusCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(DesignTokens.Color.accent)
                .frame(width: 36, height: 36)
                .background(.white.opacity(0.64), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text("本地索引已更新")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DesignTokens.Color.primaryText)
                Text("\(appModel.library.documents.count) 个文件 · 本地搜索，不上传原文件")
                    .font(.system(size: 11))
                    .foregroundStyle(DesignTokens.Color.secondaryText)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .frame(height: 58)
        .background(DesignTokens.Color.stateSurface.opacity(0.72), in: RoundedRectangle(cornerRadius: 18))
    }

    private var suggestionCard: some View {
        GlassCard(cornerRadius: 20) {
            VStack(spacing: 0) {
                suggestionRow(name: "租赁合同.pdf", detail: "最近修改", icon: "doc.text") {
                    openFirstDocumentOrNotify()
                }
                Divider().padding(.leading, 64)
                suggestionRow(name: "身份证复印件.pdf", detail: "OCR 已建立", icon: "person.text.rectangle") {
                    openFirstDocumentOrNotify()
                }
            }
        }
    }

    private func suggestionRow(name: String, detail: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(DesignTokens.Color.accent)
                    .frame(width: 36, height: 36)
                    .background(DesignTokens.Color.stateSurface, in: RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 3) {
                    Text(name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(DesignTokens.Color.primaryText)
                    Text(detail)
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
        }
        .buttonStyle(.plain)
    }

    private var noResultsContent: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(DesignTokens.Color.accent)
                .frame(width: 64, height: 64)
                .background(DesignTokens.Color.stateSurface, in: RoundedRectangle(cornerRadius: 20))
            Text("没有找到匹配文件")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(DesignTokens.Color.primaryText)
            Text("试试文件名或 OCR 正文中的其他关键词。")
                .font(.system(size: 12))
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
                            appModel.push(.document(document.id))
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundStyle(DesignTokens.Color.accent)
                                    .frame(width: 36, height: 36)
                                    .background(DesignTokens.Color.stateSurface, in: RoundedRectangle(cornerRadius: 10))
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(document.name)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(DesignTokens.Color.primaryText)
                                    Text(document.searchableText.map { String($0.prefix(28)) } ?? "PDF 文档")
                                        .font(.system(size: 11))
                                        .foregroundStyle(DesignTokens.Color.secondaryText)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11, weight: .semibold))
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

    private func openFirstDocumentOrNotify() {
        if let document = appModel.library.documents.first {
            appModel.push(.document(document.id))
        } else {
            appModel.transientMessage = "扫描或导入文件后即可查看"
        }
    }

    private var normalizedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var results: [DocumentRecord] {
        appModel.library.visibleDocuments(query: normalizedQuery)
    }
}
