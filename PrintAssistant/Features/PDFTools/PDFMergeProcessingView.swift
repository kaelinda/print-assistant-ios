import PDFKit
import SwiftUI

struct PDFMergeProcessingView: View {
    @Environment(AppModel.self) private var appModel
    let draft: PDFMergeDraft

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

                Text("合并失败")
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
                    .accessibilityLabel("正在合并 PDF")

                Text("正在合并 PDF")
                    .font(.title2.bold())

                Text("\(draft.sources.count) 个文件")
                    .foregroundStyle(.secondary)

                Text("源文件不会被修改。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(DesignTokens.Spacing.lg)
        .navigationTitle("合并 PDF")
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(errorMessage == nil)
        .task(id: attempt) {
            guard errorMessage == nil else { return }
            await merge()
        }
        .onDisappear {
            if !completed && errorMessage != nil {
                appModel.pdfImportService.cleanup(draft.sources)
            }
        }
    }

    @MainActor
    private func merge() async {
        do {
            let filename = "合并文件-\(Int(Date.now.timeIntervalSince1970)).pdf"
            let url = try await appModel.pdfOperationService.merge(
                urls: draft.sources.map(\.url),
                filename: filename
            )
            let document = try requireDocument(url)
            let values = try url.resourceValues(forKeys: [.fileSizeKey])
            let record = DocumentRecord(
                name: filename,
                pageCount: document.pageCount,
                byteCount: Int64(values.fileSize ?? 0),
                source: .generated,
                localURL: url
            )

            try appModel.library.add(record)
            appModel.pdfImportService.cleanup(draft.sources)
            completed = true
            appModel.replaceTop(with: .pdfMergeSuccess(record.id))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func requireDocument(_ url: URL) throws -> PDFDocument {
        guard let document = PDFDocument(url: url) else {
            throw PDFOperationService.OperationError.unreadablePDF
        }
        return document
    }
}
