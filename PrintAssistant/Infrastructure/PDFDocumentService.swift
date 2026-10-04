import PDFKit
import UIKit

struct PDFDocumentService {
    enum PDFError: LocalizedError {
        case unableToCreatePage
        case unableToDecodeImage
        case unableToWrite

        var errorDescription: String? {
            switch self {
            case .unableToCreatePage: "无法创建 PDF 页面。"
            case .unableToDecodeImage: "有图片无法读取，请重新选择。"
            case .unableToWrite: "无法写入 PDF 文件。"
            }
        }
    }

    func makePDF(from images: [UIImage], filename: String) throws -> URL {
        let document = PDFDocument()

        for (index, image) in images.enumerated() {
            guard let page = PDFPage(image: image) else {
                throw PDFError.unableToCreatePage
            }
            document.insert(page, at: index)
        }

        let url = try outputURL(filename: filename)

        guard document.write(to: url) else {
            throw PDFError.unableToWrite
        }
        return url
    }

    func makePhotoPDF(from draft: PhotoPDFDraft, filename: String) throws -> URL {
        let pageSize = draft.paper.sizeInPoints
        let bounds = CGRect(origin: .zero, size: pageSize)
        let printable = bounds.insetBy(dx: draft.marginPoints, dy: draft.marginPoints)
        let renderer = UIGraphicsPDFRenderer(bounds: bounds)
        let url = try outputURL(filename: filename)

        do {
            try renderer.writePDF(to: url) { context in
                for item in draft.items {
                    guard let image = UIImage(data: item.data) else {
                        continue
                    }

                    context.beginPage()
                    UIColor.white.setFill()
                    context.cgContext.fill(bounds)

                    let target = drawRect(
                        imageSize: image.size,
                        inside: printable,
                        mode: draft.fitMode
                    )

                    context.cgContext.saveGState()
                    if draft.fitMode == .fill {
                        context.cgContext.clip(to: printable)
                    }
                    image.draw(in: target)
                    context.cgContext.restoreGState()
                }
            }
        } catch {
            throw PDFError.unableToWrite
        }

        return url
    }

    private func drawRect(
        imageSize: CGSize,
        inside container: CGRect,
        mode: PhotoPDFDraft.FitMode
    ) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else {
            return container
        }

        let widthScale = container.width / imageSize.width
        let heightScale = container.height / imageSize.height
        let scale = mode == .fit
            ? min(widthScale, heightScale)
            : max(widthScale, heightScale)

        let size = CGSize(
            width: imageSize.width * scale,
            height: imageSize.height * scale
        )

        return CGRect(
            x: container.midX - size.width / 2,
            y: container.midY - size.height / 2,
            width: size.width,
            height: size.height
        )
    }

    private func outputURL(filename: String) throws -> URL {
        let directory = try documentsDirectory()
        return directory.appending(path: filename, directoryHint: .notDirectory)
    }

    private func documentsDirectory() throws -> URL {
        let base = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = base.appending(path: "Documents", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
