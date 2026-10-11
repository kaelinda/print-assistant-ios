import PDFKit
import Photos
import SwiftUI

enum PhotoExportError: LocalizedError, Equatable {
    case missingFile
    case unreadablePDF
    case lockedPDF
    case notAuthorized
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .missingFile: "文件不存在或已被移动。"
        case .unreadablePDF: "PDF 文件无法读取。"
        case .lockedPDF: "受密码保护的 PDF 需要先解锁。"
        case .notAuthorized: "没有添加照片的权限。请在系统设置中允许打印助手写入照片。"
        case .saveFailed: "照片保存失败，请重试。"
        }
    }

    static func authorizationFailure(for status: PHAuthorizationStatus) -> PhotoExportError? {
        switch status {
        case .authorized, .limited:
            return nil
        case .denied, .restricted, .notDetermined:
            return .notAuthorized
        @unknown default:
            return .notAuthorized
        }
    }
}

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
            Text("把 PDF 每一页渲染成图片并保存到照片。")
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
        guard !isWorking else { return }
        guard let document = appModel.library.document(id: documentID),
              FileManager.default.fileExists(atPath: document.localURL.path) else {
            message = PhotoExportError.missingFile.localizedDescription
            return
        }
        if document.isPasswordProtected {
            message = PhotoExportError.lockedPDF.localizedDescription
            return
        }

        isWorking = true
        message = nil
        let url = document.localURL
        Task {
            do {
                let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
                if let failure = PhotoExportError.authorizationFailure(for: status) {
                    throw failure
                }
                let images = try await renderPages(at: url)
                try await PHPhotoLibrary.shared().performChanges {
                    for image in images {
                        PHAssetCreationRequest.creationRequestForAsset(from: image)
                    }
                }
                await MainActor.run {
                    isWorking = false
                    message = "已保存 \(images.count) 页到照片"
                    appModel.transientMessage = "图片导出完成"
                }
            } catch let error as PhotoExportError {
                await MainActor.run {
                    isWorking = false
                    message = error.localizedDescription
                }
            } catch {
                await MainActor.run {
                    isWorking = false
                    message = PhotoExportError.saveFailed.localizedDescription
                }
            }
        }
    }

    private func renderPages(at url: URL) async throws -> [UIImage] {
        try await Task.detached(priority: .userInitiated) {
            guard let pdf = PDFDocument(url: url) else {
                throw PhotoExportError.unreadablePDF
            }
            guard !pdf.isLocked else {
                throw PhotoExportError.lockedPDF
            }
            guard pdf.pageCount > 0 else {
                throw PhotoExportError.unreadablePDF
            }

            var rendered: [UIImage] = []
            rendered.reserveCapacity(pdf.pageCount)
            for index in 0..<pdf.pageCount {
                try Task.checkCancellation()
                let image: UIImage? = autoreleasepool {
                    guard let page = pdf.page(at: index) else { return nil }
                    let bounds = page.bounds(for: .mediaBox).size
                    let size = OCRRecognitionService.thumbnailSize(forPage: bounds, maxDimension: 2000)
                    return page.thumbnail(of: size, for: .mediaBox)
                }
                if let image {
                    rendered.append(image)
                }
            }
            guard !rendered.isEmpty else { throw PhotoExportError.unreadablePDF }
            return rendered
        }.value
    }
}
