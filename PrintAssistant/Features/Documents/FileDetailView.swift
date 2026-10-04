import SwiftUI

struct FileDetailView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    let documentID: DocumentRecord.ID

    @State private var isRenaming = false
    @State private var renameText = ""
    @State private var isConfirmingDelete = false
    @State private var operationError: String?
    @State private var isPreparingOCR = false

    var body: some View {
        Group {
            if let document = appModel.library.document(id: documentID) {
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                        PDFThumbnailView(url: document.localURL)
                            .frame(maxWidth: .infinity)
                            .frame(height: 420)
                            .background(
                                Color.secondary.opacity(0.08),
                                in: RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                            )

                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                            Text(document.name)
                                .font(.title3.bold())
                                .textSelection(.enabled)

                            Text("\(document.pageCount) 页 · \(document.byteCount.formatted(.byteCount(style: .file)))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text("来源：\(sourceName(document.source)) · \(document.modifiedAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(.footnote)
                                .foregroundStyle(.secondary)

                            if document.hasOCRText {
                                Label("已建立文字索引", systemImage: "text.magnifyingglass")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        PrimaryActionButton(title: "预览 / 打印", state: .enabled) {
                            appModel.push(.pdfPreview(document.id))
                        }

                        Button {
                            prepareOCR(for: document)
                        } label: {
                            HStack {
                                if isPreparingOCR {
                                    ProgressView()
                                } else {
                                    Image(systemName: "text.viewfinder")
                                }
                                Text(document.hasOCRText ? "重新识别文字" : "识别文字")
                            }
                            .frame(maxWidth: .infinity, minHeight: 50)
                        }
                        .buttonStyle(.bordered)
                        .disabled(isPreparingOCR)
                    }
                    .padding(DesignTokens.Spacing.lg)
                }
                .navigationTitle("文件详情")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button {
                                renameText = (document.name as NSString).deletingPathExtension
                                isRenaming = true
                            } label: {
                                Label("重命名", systemImage: "pencil")
                            }

                            Button(role: .destructive) {
                                isConfirmingDelete = true
                            } label: {
                                Label("删除文件", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                        .accessibilityLabel("文件操作")
                    }
                }
                .alert("重命名", isPresented: $isRenaming) {
                    TextField("文件名", text: $renameText)
                    Button("取消", role: .cancel) {}
                    Button("保存") { rename() }
                } message: {
                    Text("文件扩展名会保持不变。")
                }
                .confirmationDialog(
                    "删除“\(document.name)”？",
                    isPresented: $isConfirmingDelete,
                    titleVisibility: .visible
                ) {
                    Button("永久删除", role: .destructive) { delete() }
                    Button("取消", role: .cancel) {}
                } message: {
                    Text("此操作会从本机永久删除文件，无法撤销。")
                }
            } else {
                ContentUnavailableView("文件不存在", systemImage: "doc.badge.exclamationmark")
            }
        }
        .alert("无法完成操作", isPresented: .init(
            get: { operationError != nil },
            set: { if !$0 { operationError = nil } }
        )) {
            Button("好", role: .cancel) {}
        } message: {
            Text(operationError ?? "未知错误")
        }
    }

    private func prepareOCR(for document: DocumentRecord) {
        guard !isPreparingOCR else { return }
        isPreparingOCR = true

        Task {
            do {
                let url = document.localURL
                let data = try await Task.detached(priority: .userInitiated) {
                    try Data(contentsOf: url)
                }.value

                isPreparingOCR = false
                appModel.push(.ocrProcessing(.init(
                    data: data,
                    kind: .pdf,
                    displayName: document.name,
                    associatedDocumentID: document.id
                )))
            } catch {
                isPreparingOCR = false
                operationError = error.localizedDescription
            }
        }
    }

    private func rename() {
        do {
            try appModel.library.rename(id: documentID, to: renameText)
            appModel.transientMessage = "已重命名"
        } catch {
            operationError = error.localizedDescription
        }
    }

    private func delete() {
        do {
            try appModel.library.delete(id: documentID)
            dismiss()
            appModel.transientMessage = "文件已删除"
        } catch {
            operationError = error.localizedDescription
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
