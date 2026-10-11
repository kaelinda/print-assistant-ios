import PDFKit
import Photos
import SwiftUI

struct ImageExportView: View {
    @Environment(AppModel.self) private var appModel
    let documentID: DocumentRecord.ID
    @State private var isWorking = false
    @State private var message: String?

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 52))
                .foregroundStyle(DesignTokens.Color.accent)
            Text("导出图片").font(.title2.bold())
            Text("把 PDF 每一页渲染成 PNG 并保存到照片。")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            PrimaryActionButton(title: "导出到照片", state: isWorking ? .processing : .enabled) {
                export()
            }
            if let message {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding(24)
        .navigationTitle("导出图片")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func export() {
        guard !isWorking, let document = appModel.library.document(id: documentID),
              let pdf = PDFDocument(url: document.localURL) else { return }
        isWorking = true
        Task {
            do {
                let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
                guard status == .authorized || status == .limited else {
                    throw CocoaError(.fileWriteNoPermission)
                }
                for index in 0..<pdf.pageCount {
                    guard let page = pdf.page(at: index) else { continue }
                    let image = page.thumbnail(of: CGSize(width: 1600, height: 2200), for: .mediaBox)
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                }
                await MainActor.run {
                    isWorking = false
                    message = "已提交 \(pdf.pageCount) 页到照片"
                    appModel.transientMessage = "图片导出完成"
                }
            } catch {
                await MainActor.run {
                    isWorking = false
                    message = error.localizedDescription
                }
            }
        }
    }
}
