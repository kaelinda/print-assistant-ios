import PDFKit
import UIKit

struct PDFDocumentService: Sendable {
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

        let url = try Self.outputURL(filename: filename)

        guard document.write(to: url) else {
            throw PDFError.unableToWrite
        }
        return url
    }

    func makePhotoPDF(from draft: PhotoPDFDraft, filename: String) async throws -> URL {
        try await Task.detached(priority: .userInitiated) {
            try Self.renderPhotoPDF(from: draft, filename: filename)
        }.value
    }

    private static func renderPhotoPDF(from draft: PhotoPDFDraft, filename: String) throws -> URL {
        for item in draft.items {
            let isReadable = autoreleasepool {
                UIImage(data: item.data) != nil
            }
            guard isReadable else {
                throw PDFError.unableToDecodeImage
            }
        }

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

                    let target = Self.drawRect(
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

        guard
            let verification = PDFDocument(url: url),
            verification.pageCount == draft.items.count
        else {
            try? FileManager.default.removeItem(at: url)
            throw PDFError.unableToWrite
        }

        return url
    }

    func makeIDCopyPDF(from draft: IDCopyDraft, filename: String) async throws -> URL {
        try await Task.detached(priority: .userInitiated) {
            try Self.renderIDCopyPDF(from: draft, filename: filename)
        }.value
    }

    private static func renderIDCopyPDF(from draft: IDCopyDraft, filename: String) throws -> URL {
        guard
            let frontData = draft.frontData,
            let backData = draft.backData,
            let front = UIImage(data: frontData),
            let back = UIImage(data: backData)
        else {
            throw PDFError.unableToDecodeImage
        }

        let bounds = CGRect(origin: .zero, size: PhysicalPrintGeometry.a4Size)
        let card = PhysicalPrintGeometry.id1CardSize
        let gap = PhysicalPrintGeometry.points(millimeters: 20)
        let totalHeight = card.height * 2 + gap
        let firstY = bounds.midY - totalHeight / 2

        let frontRect = CGRect(
            x: bounds.midX - card.width / 2,
            y: firstY,
            width: card.width,
            height: card.height
        )
        let backRect = CGRect(
            x: bounds.midX - card.width / 2,
            y: firstY + card.height + gap,
            width: card.width,
            height: card.height
        )

        let renderer = UIGraphicsPDFRenderer(bounds: bounds)
        let url = try Self.outputURL(filename: filename)

        do {
            try renderer.writePDF(to: url) { context in
                context.beginPage()
                UIColor.white.setFill()
                context.cgContext.fill(bounds)

                Self.drawImage(front, inside: frontRect, context: context.cgContext)
                Self.drawImage(back, inside: backRect, context: context.cgContext)
            }
        } catch {
            throw PDFError.unableToWrite
        }

        guard let verification = PDFDocument(url: url), verification.pageCount == 1 else {
            try? FileManager.default.removeItem(at: url)
            throw PDFError.unableToWrite
        }

        do {
            try FileManager.default.setAttributes(
                [.protectionKey: FileProtectionType.complete],
                ofItemAtPath: url.path()
            )
        } catch {
            try? FileManager.default.removeItem(at: url)
            throw PDFError.unableToWrite
        }

        return url
    }

    private static func drawImage(_ image: UIImage, inside rect: CGRect, context: CGContext) {
        let target = drawRect(imageSize: image.size, inside: rect, mode: .fill)
        context.saveGState()
        context.clip(to: rect)
        image.draw(in: target)
        context.restoreGState()
    }

    private static func drawRect(
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

    private static func outputURL(filename: String) throws -> URL {
        let directory = try documentsDirectory()
        return directory.appending(path: filename, directoryHint: .notDirectory)
    }

    private static func documentsDirectory() throws -> URL {
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
