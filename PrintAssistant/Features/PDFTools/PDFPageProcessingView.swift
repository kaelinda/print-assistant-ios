import PDFKit
import SwiftUI

struct PDFPageProcessingView: View {
    @Environment(AppModel.self) private var appModel
    let draft: PDFPageManagementDraft

    @State private var errorMessage: String?
    @State private var attempt = 0
    @State private var completed = false

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Spacer()

            if let errorMessage {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 48))
                    .foregroundStyle(DesignTokens.Color.warning)
                    .accessibilityHidden(true)
                Text("页面处理失败")
                    .font(.title2.bold())
                Text(errorMessage)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                PrimaryActionButton(title: "重试", state: .enabled) {
                    self.errorMessage = nil
                    attempt += 1
                }
            } else {
                ProgressView()
                    .controlSize(.large)
                    .accessibilityLabel("正在生成新的 PDF")
                Text("正在生成新 PDF")
                    .font(.title2.bold())
                Text("\(draft.pageIndexes.count) 页")
                    .foregroundStyle(.secondary)
                Text("源文件不会被修改。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(DesignTokens.Spacing.lg)
        .navigationTitle("页面管理")
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(errorMessage == nil)
        .task(id: attempt) {
            guard errorMessage == nil else { return }
            await generate()
        }
        .onDisappear {
            if !completed && errorMessage != nil && draft.source.isTemporary {
                appModel.pdfImportService.cleanup([draft.source])
            }
        }
    }

    @MainActor
    private func generate() async {
        do {
            let filename = "页面调整-\(Int(Date.now.timeIntervalSince1970)).pdf"
            let url = try await appModel.pdfOperationService.applyPagePlan(
                .init(sourceURL: draft.source.url, pageIndexes: draft.pageIndexes),
                filename: filename
            )
            guard let document = PDFDocument(url: url) else {
                throw PDFOperationService.OperationError.unreadablePDF
            }
            let values = try url.resourceValues(forKeys: [.fileSizeKey])
            let record = DocumentRecord(
                name: filename,
                pageCount: document.pageCount,
                byteCount: Int64(values.fileSize ?? 0),
                source: .generated,
                localURL: url
            )

            do {
                try appModel.library.add(record)
            } catch {
                try? FileManager.default.removeItem(at: url)
                throw error
            }

            if draft.source.isTemporary {
                appModel.pdfImportService.cleanup([draft.source])
            }
            completed = true
            appModel.replaceTop(with: .pdfPageSuccess(record.id))
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
