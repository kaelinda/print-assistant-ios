import SwiftUI

struct FileDetailView: View {
    @Environment(AppModel.self) private var appModel
    let documentID: DocumentRecord.ID

    var body: some View {
        Group {
            if let document = appModel.library.document(id: documentID) {
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                        PDFThumbnailView(url: document.localURL)
                            .frame(maxWidth: .infinity)
                            .frame(height: 420)
                            .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: DesignTokens.Radius.card))

                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                            Text(document.name).font(.title3.bold()).textSelection(.enabled)
                            Text("\(document.pageCount) 页 · \(document.byteCount.formatted(.byteCount(style: .file)))")
                                .font(.subheadline).foregroundStyle(.secondary)
                            Text("来源：\(sourceName(document.source)) · \(document.modifiedAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(.footnote).foregroundStyle(.secondary)
                        }

                        PrimaryActionButton(title: "预览 / 打印", state: .enabled) {
                            appModel.push(.pdfPreview(document.id))
                        }
                    }
                    .padding(DesignTokens.Spacing.lg)
                }
                .navigationTitle("文件详情")
                .navigationBarTitleDisplayMode(.inline)
            } else {
                ContentUnavailableView("文件不存在", systemImage: "doc.badge.exclamationmark")
            }
        }
    }

    private func sourceName(_ source: DocumentRecord.Source) -> String {
        switch source {
        case .scan: "扫描"
        case .photos: "照片"
        case .files: "文件"
        case .generated: "生成"
        }
    }
}
