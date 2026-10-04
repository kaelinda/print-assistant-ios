import PDFKit
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
                Text("让文字区域完整进入画面。可以连续拍多页，完成后会按页序识别。")
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
                    guard !images.isEmpty else { return }

                    do {
                        let input = try makeOCRInput(from: images)
                        appModel.push(.ocrProcessing(input))
                    } catch {
                        errorMessage = error.localizedDescription
                    }
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

    private func makeOCRInput(from images: [UIImage]) throws -> OCRInput {
        if images.count == 1 {
            guard let data = images[0].jpegData(compressionQuality: 0.96) else {
                throw CocoaError(.fileWriteUnknown)
            }
            return OCRInput(data: data, kind: .image, displayName: "OCR 拍照")
        }

        let document = PDFDocument()
        for (index, image) in images.enumerated() {
            guard let page = PDFPage(image: image) else {
                throw CocoaError(.fileWriteUnknown)
            }
            document.insert(page, at: index)
        }

        guard let data = document.dataRepresentation() else {
            throw CocoaError(.fileWriteUnknown)
        }

        return OCRInput(
            data: data,
            kind: .pdf,
            displayName: "OCR 拍照（\(images.count) 页）"
        )
    }
}
