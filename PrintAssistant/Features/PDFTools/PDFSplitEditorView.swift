import SwiftUI

struct PDFSplitEditorView: View {
    @Environment(AppModel.self) private var appModel
    @State private var draft: PDFSplitDraft
    @State private var isNavigatingForward = false

    init(draft: PDFSplitDraft) {
        _draft = State(initialValue: draft)
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                    Text(draft.source.displayName)
                        .font(.headline)
                    Text("共 \(draft.pageCount) 页")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("输出范围") {
                ForEach(Array(draft.ranges.indices), id: \.self) { index in
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        HStack {
                            Text("文件 \(index + 1)")
                                .font(.headline)
                            Spacer()
                            if draft.ranges.count > 1 {
                                Button(role: .destructive) {
                                    draft.ranges.remove(at: index)
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("删除范围 \(index + 1)")
                            }
                        }

                        HStack {
                            Stepper(
                                "起始 \(draft.ranges[index].startPage)",
                                value: startBinding(index),
                                in: 1...draft.pageCount
                            )
                            Stepper(
                                "结束 \(draft.ranges[index].endPage)",
                                value: endBinding(index),
                                in: 1...draft.pageCount
                            )
                        }
                        .font(.subheadline)
                    }
                    .padding(.vertical, DesignTokens.Spacing.xxs)
                }

                Button {
                    addRange()
                } label: {
                    Label("添加输出范围", systemImage: "plus")
                }
            }

            Section {
                Text("页码从 1 开始，范围包含起始页和结束页。每个范围会生成一个新的 PDF；源文件保持不变。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .safeAreaInset(edge: .bottom) {
            PrimaryActionButton(
                title: "生成 \(draft.ranges.count) 个 PDF",
                state: draft.isValid ? .enabled : .disabled
            ) {
                isNavigatingForward = true
                appModel.push(.pdfSplitProcessing(draft))
            }
            .padding(DesignTokens.Spacing.lg)
            .background(.regularMaterial)
        }
        .navigationTitle("设置页码范围")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            if !isNavigatingForward && draft.source.isTemporary {
                appModel.pdfImportService.cleanup([draft.source])
            }
        }
    }

    private func startBinding(_ index: Int) -> Binding<Int> {
        Binding {
            draft.ranges[index].startPage
        } set: { value in
            let end = max(value, draft.ranges[index].endPage)
            draft.ranges[index] = .init(startPage: value, endPage: end)
        }
    }

    private func endBinding(_ index: Int) -> Binding<Int> {
        Binding {
            draft.ranges[index].endPage
        } set: { value in
            let start = min(value, draft.ranges[index].startPage)
            draft.ranges[index] = .init(startPage: start, endPage: value)
        }
    }

    private func addRange() {
        let lastEnd = draft.ranges.last?.endPage ?? 0
        let next = min(draft.pageCount, lastEnd + 1)
        draft.ranges.append(.init(startPage: next, endPage: next))
    }
}
