import SwiftUI

struct IDCopyConfirmView: View {
    @Environment(AppModel.self) private var appModel

    let draft: IDCopyDraft
    let side: IDCopyDraft.Side
    let capturedData: Data

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Spacer()

            if let image = UIImage(data: capturedData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 360)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.card))
                    .shadow(color: .black.opacity(0.10), radius: 16, y: 8)
                    .accessibilityLabel("身份证\(side.displayName)拍摄结果")
            }

            VStack(spacing: DesignTokens.Spacing.xs) {
                Text("检查\(side.displayName)")
                    .font(.title2.bold())
                Text("确认文字清晰、没有明显反光，并且四个边角都完整。")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            HStack(spacing: DesignTokens.Spacing.sm) {
                Button("重拍") {
                    appModel.replaceTop(with: .idCopyCapture(draft, side))
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .frame(maxWidth: .infinity)

                Button(side == .front ? "继续拍国徽面" : "使用照片") {
                    usePhoto()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .navigationTitle("确认照片")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func usePhoto() {
        var updated = draft

        switch side {
        case .front:
            updated.frontData = capturedData
            appModel.replaceTop(with: .idCopyCapture(updated, .back))
        case .back:
            updated.backData = capturedData
            appModel.replaceTop(with: .idCopyLayout(updated))
        }
    }
}
