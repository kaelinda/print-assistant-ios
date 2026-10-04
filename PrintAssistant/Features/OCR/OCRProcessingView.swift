import SwiftUI

struct OCRProcessingView: View {
    @Environment(AppModel.self) private var appModel
    let input: OCRInput

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

                Text("无法识别文字")
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
                    .accessibilityLabel("正在识别文字")

                Text("正在识别文字")
                    .font(.title2.bold())

                Text(input.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("识别在设备上完成。处理时间会随页数和内容复杂度变化。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding(DesignTokens.Spacing.lg)
        .navigationTitle("文字识别")
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(errorMessage == nil)
        .task(id: attempt) {
            guard errorMessage == nil else { return }
            await recognize()
        }
    }

    @MainActor
    private func recognize() async {
        do {
            let result = try await appModel.ocrService.recognize(input)
            if let documentID = input.associatedDocumentID, !result.isEmpty {
                do {
                    try appModel.library.updateSearchableText(id: documentID, text: result.text)
                } catch {
                    appModel.transientMessage = "文字已识别，但搜索索引保存失败"
                }
            }
            appModel.replaceTop(with: .ocrResult(result))
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
