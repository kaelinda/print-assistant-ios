import SwiftUI

struct IDCopyGeneratingView: View {
    @Environment(AppModel.self) private var appModel
    let draft: IDCopyDraft

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
                Text("生成失败")
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
                    .accessibilityLabel("正在生成身份证复印 PDF")
                Text("正在生成 A4 PDF")
                    .font(.title2.bold())
                Text("保持 85.60 × 53.98 mm 证件外框尺寸")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(DesignTokens.Spacing.lg)
        .navigationTitle("身份证复印")
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(errorMessage == nil)
        .task(id: attempt) {
            guard errorMessage == nil else { return }
            await generate()
        }
    }

    @MainActor
    private func generate() async {
        do {
            let filename = "身份证复印件-\(Int(Date.now.timeIntervalSince1970)).pdf"
            let url = try await appModel.pdfService.makeIDCopyPDF(from: draft, filename: filename)
            let values = try url.resourceValues(forKeys: [.fileSizeKey])
            let record = DocumentRecord(
                name: filename,
                pageCount: 1,
                byteCount: Int64(values.fileSize ?? 0),
                source: .generated,
                localURL: url
            )

            try appModel.library.add(record)
            appModel.replaceTop(with: .idCopySuccess(record.id))
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
