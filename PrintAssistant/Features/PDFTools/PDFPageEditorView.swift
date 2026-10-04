import PDFKit
import SwiftUI

struct PDFPageEditorView: View {
    @Environment(AppModel.self) private var appModel
    @State private var draft: PDFPageManagementDraft
    @State private var isNavigatingForward = false

    init(draft: PDFPageManagementDraft) {
        _draft = State(initialValue: draft)
    }

    var body: some View {
        List {
            Section {
                Text(draft.source.displayName)
                    .font(.headline)
                Text("\(draft.pageIndexes.count) / \(draft.originalPageCount) 页")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("页面顺序") {
                ForEach(draft.pageIndexes, id: \.self) { originalIndex in
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        thumbnail(originalIndex)
                            .frame(width: 48, height: 64)
                            .background(Color.secondary.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                            Text("原第 \(originalIndex + 1) 页")
                                .font(.body.weight(.medium))
                            Text("拖动调整输出顺序")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button(role: .destructive) {
                            remove(originalIndex)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.plain)
                        .disabled(draft.pageIndexes.count <= 1)
                        .accessibilityLabel("删除原第 \(originalIndex + 1) 页")
                    }
                    .frame(minHeight: 72)
                }
                .onMove { offsets, destination in
                    draft.pageIndexes.move(fromOffsets: offsets, toOffset: destination)
                }
            }

            Section {
                Text("页面管理始终生成一个新 PDF，源文件不会被修改。至少保留一页。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .safeAreaInset(edge: .bottom) {
            PrimaryActionButton(
                title: "生成新 PDF",
                state: draft.canGenerate && draft.hasChanges ? .enabled : .disabled
            ) {
                isNavigatingForward = true
                appModel.push(.pdfPageProcessing(draft))
            }
            .padding(DesignTokens.Spacing.lg)
            .background(.regularMaterial)
        }
        .navigationTitle("页面管理")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { EditButton() }
        .onDisappear {
            if !isNavigatingForward && draft.source.isTemporary {
                appModel.pdfImportService.cleanup([draft.source])
            }
        }
    }

    @ViewBuilder
    private func thumbnail(_ index: Int) -> some View {
        if
            let document = PDFDocument(url: draft.source.url),
            let page = document.page(at: index)
        {
            Image(uiImage: page.thumbnail(
                of: CGSize(width: 180, height: 240),
                for: .mediaBox
            ))
            .resizable()
            .scaledToFit()
        } else {
            Image(systemName: "doc")
                .foregroundStyle(.secondary)
        }
    }

    private func remove(_ originalIndex: Int) {
        guard draft.pageIndexes.count > 1 else { return }
        draft.pageIndexes.removeAll { $0 == originalIndex }
    }
}
