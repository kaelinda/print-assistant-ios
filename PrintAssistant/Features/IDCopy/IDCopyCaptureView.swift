import SwiftUI
import VisionKit

struct IDCopyCaptureView: View {
    @Environment(AppModel.self) private var appModel

    let draft: IDCopyDraft
    let side: IDCopyDraft.Side

    @State private var isPresentingCamera = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Spacer()

            Image(systemName: side == .front ? "person.text.rectangle" : "creditcard")
                .font(.system(size: 58))
                .foregroundStyle(DesignTokens.Color.accent)
                .accessibilityHidden(true)

            VStack(spacing: DesignTokens.Spacing.xs) {
                Text("拍摄身份证\(side.displayName)")
                    .font(.title2.bold())

                Text("每次只拍一面。请让四个边角完整可见，并尽量避免反光。")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            PrimaryActionButton(
                title: "拍摄\(side.displayName)",
                state: VNDocumentCameraViewController.isSupported ? .enabled : .disabled
            ) {
                isPresentingCamera = true
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .navigationTitle(side.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $isPresentingCamera) {
            DocumentCameraView(
                onComplete: { images in
                    isPresentingCamera = false

                    guard images.count == 1 else {
                        errorMessage = "身份证每次只需要拍摄一面，请重新拍摄。"
                        return
                    }
                    guard let data = images[0].jpegData(compressionQuality: 0.98) else {
                        errorMessage = "无法读取拍摄结果，请重新拍摄。"
                        return
                    }

                    appModel.push(.idCopyConfirm(draft, side, data))
                },
                onCancel: {
                    isPresentingCamera = false
                },
                onFailure: { error in
                    isPresentingCamera = false
                    errorMessage = error.localizedDescription
                }
            )
            .ignoresSafeArea()
        }
        .alert("无法使用这张照片", isPresented: .init(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("好", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "未知错误")
        }
    }
}
