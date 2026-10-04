import SwiftUI
import VisionKit

struct ScannerView: View {
    @Environment(AppModel.self) private var appModel
    @State private var isPresentingCamera = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Spacer()
            Image(systemName: "doc.viewfinder")
                .font(.system(size: 58))
                .foregroundStyle(DesignTokens.Color.accent)
                .accessibilityHidden(true)
            VStack(spacing: DesignTokens.Spacing.xs) {
                Text("扫描文档").font(.title2.bold())
                Text("自动识别纸张边缘并校正文档透视。")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
            PrimaryActionButton(title: "打开相机", state: VNDocumentCameraViewController.isSupported ? .enabled : .disabled) {
                isPresentingCamera = true
            }
            if !VNDocumentCameraViewController.isSupported {
                Text("当前设备不支持文档扫描。请在支持相机的 iPhone 上运行。")
                    .font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .navigationTitle("扫描")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $isPresentingCamera) {
            DocumentCameraView(
                onComplete: { images in
                    isPresentingCamera = false
                    guard !images.isEmpty else { return }
                    appModel.push(.scanReview(.init(pages: images)))
                },
                onCancel: { isPresentingCamera = false },
                onFailure: { error in isPresentingCamera = false; errorMessage = error.localizedDescription }
            )
            .ignoresSafeArea()
        }
        .alert("无法扫描", isPresented: .init(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("好", role: .cancel) {}
        } message: { Text(errorMessage ?? "未知错误") }
    }
}
