import SwiftUI
import VisionKit

struct OCRCameraView: View {
    @Environment(AppModel.self) private var appModel

    @State private var isPresentingCamera = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Spacer()

            Image(systemName: "text.viewfinder")
                .font(.system(size: 58))
                .foregroundStyle(DesignTokens.Color.accent)
                .accessibilityHidden(true)

            VStack(spacing: DesignTokens.Spacing.xs) {
                Text("拍照识别文字")
                    .font(.title2.bold())
                Text("让文字区域完整进入画面。拍摄后会直接进入识别，不会混入普通扫描任务。")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            PrimaryActionButton(
                title: "打开相机",
                state: VNDocumentCameraViewController.isSupported ? .enabled : .disabled
            ) {
                isPresentingCamera = true
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .navigationTitle("OCR 拍照")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $isPresentingCamera) {
            DocumentCameraView(
                onComplete: { images in
                    isPresentingCamera = false
                    guard
                        let image = images.first,
                        let data = image.jpegData(compressionQuality: 0.96)
                    else { return }

                    appModel.push(.ocrProcessing(.init(
                        data: data,
                        kind: .image,
                        displayName: "OCR 拍照"
                    )))
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
        .alert("无法拍摄", isPresented: .init(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("好", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "未知错误")
        }
    }
}
