import SwiftUI

struct PhotoPDFGeneratingView: View {
    @Environment(AppModel.self) private var appModel
    let draft: PhotoPDFDraft

    @State private var errorMessage: String?
    @State private var attempt = 0

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Spacer()

            if let errorMessage {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 48))
                    .foregroundStyle(DesignTokens.Color.warning)
                    .accessibilityHidden(true)

                Text("PDF 生成失败")
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
                    .accessibilityLabel("正在生成 PDF")

                Text("正在生成 PDF")
                    .font(.title2.bold())

                Text("\(draft.items.count) 张图片 · \(draft.paper.displayName)")
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(DesignTokens.Spacing.lg)
        .navigationTitle("图片转 PDF")
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(errorMessage == nil)
        .task(id: attempt) {
            guard errorMessage == nil else { return }
            await generate()
        }
    }

    @MainActor
    private func generate() async {
        await Task.yield()

        do {
            let filename = "图片合集-\(Int(Date.now.timeIntervalSince1970)).pdf"
            let url = try appModel.pdfService.makePhotoPDF(from: draft, filename: filename)
            let values = try url.resourceValues(forKeys: [.fileSizeKey])
            let record = DocumentRecord(
                name: filename,
                pageCount: draft.items.count,
                byteCount: Int64(values.fileSize ?? 0),
                source: .photos,
                localURL: url
            )

            try appModel.library.add(record)
            appModel.replaceTop(with: .photoPDFSuccess(record.id))
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
