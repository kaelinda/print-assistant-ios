import Foundation
import ImageIO
import PDFKit
@preconcurrency import Vision

struct OCRRecognitionService: Sendable {
    /// Longest side of a page bitmap sent to Vision.
    static let maxPixelDimension: CGFloat = 1600

    enum RecognitionError: LocalizedError {
        case invalidImage
        case invalidPDF
        case lockedPDF
        case noPages

        var errorDescription: String? {
            switch self {
            case .invalidImage: String(localized: "无法读取图片。")
            case .invalidPDF: String(localized: "无法读取 PDF。")
            case .lockedPDF: String(localized: "受密码保护的 PDF 需要先解锁。")
            case .noPages: String(localized: "文件中没有可识别的页面。")
            }
        }
    }

    func recognize(_ input: OCRInput) async throws -> OCRResult {
        let task = Task.detached(priority: .userInitiated) { () throws -> (String, Int) in
            switch input.source {
            case .imageData(let data):
                let text = try Self.recognizeImageData(data)
                return (text, 1)
            case .imageFile(let url):
                let text = try Self.recognizeImageFile(url)
                return (text, 1)
            case .pdfFile(let url):
                return try Self.recognizePDF(at: url)
            }
        }

        let payload = try await withTaskCancellationHandler {
            try await task.value
        } onCancel: {
            task.cancel()
        }

        return OCRResult(
            text: payload.0,
            sourceName: input.displayName,
            pageCount: payload.1
        )
    }

    /// Scales a PDF page so its longest side is `maxDimension` pixels.
    static func thumbnailSize(forPage pageSize: CGSize, maxDimension: CGFloat = maxPixelDimension) -> CGSize {
        let longSide = max(pageSize.width, pageSize.height)
        guard longSide > 0, maxDimension > 0 else {
            return CGSize(width: 1, height: 1)
        }
        let scale = maxDimension / longSide
        return CGSize(
            width: max(1, pageSize.width * scale),
            height: max(1, pageSize.height * scale)
        )
    }

    private static func recognizePDF(at url: URL) throws -> (String, Int) {
        guard let document = PDFDocument(url: url) else {
            throw RecognitionError.invalidPDF
        }
        guard !document.isLocked else {
            throw RecognitionError.lockedPDF
        }
        guard document.pageCount > 0 else {
            throw RecognitionError.noPages
        }

        var pages: [String] = []
        pages.reserveCapacity(document.pageCount)

        for index in 0..<document.pageCount {
            try Task.checkCancellation()
            let text: String = try autoreleasepool {
                guard let page = document.page(at: index) else { return "" }
                let bounds = page.bounds(for: .mediaBox)
                let thumbnail = page.thumbnail(
                    of: thumbnailSize(forPage: bounds.size),
                    for: .mediaBox
                )
                guard let image = thumbnail.cgImage else { return "" }
                return try recognizeText(in: image)
            }
            if !text.isEmpty {
                pages.append(text)
            }
        }

        return (pages.joined(separator: "\n\n"), document.pageCount)
    }

    private static func recognizeImageData(_ data: Data) throws -> String {
        try autoreleasepool {
            guard
                let source = CGImageSourceCreateWithData(data as CFData, nil),
                let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
            else {
                throw RecognitionError.invalidImage
            }
            return try recognizeText(in: image)
        }
    }

    private static func recognizeImageFile(_ url: URL) throws -> String {
        try autoreleasepool {
            guard
                let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
            else {
                throw RecognitionError.invalidImage
            }
            return try recognizeText(in: image)
        }
    }
}

private func recognizeText(in image: CGImage) throws -> String {
    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = true
    request.recognitionLanguages = ["zh-Hans", "en-US"]

    let handler = VNImageRequestHandler(cgImage: image, options: [:])
    try handler.perform([request])

    return (request.results ?? [])
        .compactMap { $0.topCandidates(1).first?.string }
        .joined(separator: "\n")
}
