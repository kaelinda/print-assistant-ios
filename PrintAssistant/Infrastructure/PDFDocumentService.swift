import PDFKit
import UIKit

struct PDFDocumentService: Sendable {
    enum PDFError: LocalizedError {
        case unableToCreatePage
        case unableToDecodeImage
        case unableToWrite

        var errorDescription: String? {
            switch self {
            case .unableToCreatePage: String(localized: "无法创建 PDF 页面。")
            case .unableToDecodeImage: String(localized: "有图片无法读取，请重新选择。")
            case .unableToWrite: String(localized: "无法写入 PDF 文件。")
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
            try? FileManager.default.removeItem(at: url)
            throw PDFError.unableToWrite
        }
        return url
    }

    func makePhotoPDF(from draft: PhotoPDFDraft, filename: String) async throws -> URL {
        try Task.checkCancellation()
        return try await Self.runCancellable {
            try Self.renderPhotoPDF(from: draft, filename: filename)
        }
    }

    private static func renderPhotoPDF(from draft: PhotoPDFDraft, filename: String) throws -> URL {
        for item in draft.items {
            try Task.checkCancellation()
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
            try Task.checkCancellation()
        } catch is CancellationError {
            try? FileManager.default.removeItem(at: url)
            throw CancellationError()
        } catch {
            try? FileManager.default.removeItem(at: url)
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
        try Task.checkCancellation()
        return try await Self.runCancellable {
            try Self.renderIDCopyPDF(from: draft, filename: filename)
        }
    }

    func makePhotoIDPDF(from draft: PhotoIDDraft, filename: String) async throws -> URL {
        try Task.checkCancellation()
        return try await Self.runCancellable {
            guard let image = UIImage(data: draft.data) else {
                throw PDFError.unableToDecodeImage
            }

            let spec = PhotoIDGeometry.spec(for: draft.sizeName)
            let portrait = Self.croppedPhotoID(image, cardSize: spec.cardSize, offset: draft.cropOffset)
            let pageSize = PhysicalPrintGeometry.a4Size
            let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: pageSize))
            let url = try Self.outputURL(filename: filename)
            let cardRects = PhotoIDGeometry.cardRects(for: spec, pageSize: pageSize)

            do {
                try renderer.writePDF(to: url) { context in
                    context.beginPage()
                    UIColor.white.setFill()
                    context.cgContext.fill(CGRect(origin: .zero, size: pageSize))

                    for rect in cardRects {
                        let background: UIColor = switch draft.background {
                        case .white: .white
                        case .blue: UIColor(red: 0.34, green: 0.58, blue: 0.88, alpha: 1)
                        case .red: UIColor(red: 0.84, green: 0.22, blue: 0.24, alpha: 1)
                        }
                        background.setFill()
                        context.cgContext.fill(rect)
                        context.cgContext.saveGState()
                        context.cgContext.clip(to: rect)
                        let drawRect = Self.aspectFillRect(portrait.size, in: rect)
                        portrait.draw(in: drawRect)
                        context.cgContext.restoreGState()
                    }
                }
                try Task.checkCancellation()
            } catch is CancellationError {
                try? FileManager.default.removeItem(at: url)
                throw CancellationError()
            } catch {
                try? FileManager.default.removeItem(at: url)
                throw PDFError.unableToWrite
            }

            guard let verification = PDFDocument(url: url), verification.pageCount == 1 else {
                try? FileManager.default.removeItem(at: url)
                throw PDFError.unableToWrite
            }
            return url
        }
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
            try Task.checkCancellation()
        } catch is CancellationError {
            try? FileManager.default.removeItem(at: url)
            throw CancellationError()
        } catch {
            try? FileManager.default.removeItem(at: url)
            throw PDFError.unableToWrite
        }

        guard let verification = PDFDocument(url: url), verification.pageCount == 1 else {
            try? FileManager.default.removeItem(at: url)
            throw PDFError.unableToWrite
        }

        do {
            try FileManager.default.setAttributes(
                [.protectionKey: FileProtectionType.complete],
                ofItemAtPath: url.path
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

    private static func croppedPhotoID(_ image: UIImage, cardSize: CGSize, offset: CGSize) -> UIImage {
        let crop = PhotoIDGeometry.cropRect(imageSize: image.size, aspect: cardSize, offset: offset)
        guard crop.width > 1, crop.height > 1 else { return image }
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: crop.size, format: format)
        return renderer.image { _ in
            image.draw(at: CGPoint(x: -crop.origin.x, y: -crop.origin.y))
        }
    }

    private static func aspectFillRect(_ imageSize: CGSize, in rect: CGRect) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else { return rect }
        let scale = max(rect.width / imageSize.width, rect.height / imageSize.height)
        let size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        return CGRect(
            x: rect.midX - size.width / 2,
            y: rect.midY - size.height / 2,
            width: size.width,
            height: size.height
        )
    }

    private static func documentsDirectory() throws -> URL {
        let directory = LibraryPaths.filesDirectory()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private static func runCancellable<T: Sendable>(
        _ operation: @escaping @Sendable () throws -> T
    ) async throws -> T {
        let task = Task.detached(priority: .userInitiated, operation: operation)
        return try await withTaskCancellationHandler {
            try await task.value
        } onCancel: {
            task.cancel()
        }
    }
}
