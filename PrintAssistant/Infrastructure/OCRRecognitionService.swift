import Foundation
import ImageIO
import PDFKit
@preconcurrency import Vision

struct OCRRecognitionService {
    enum RecognitionError: LocalizedError {
        case invalidImage
        case invalidPDF
        case noPages

        var errorDescription: String? {
            switch self {
            case .invalidImage: "无法读取图片。"
            case .invalidPDF: "无法读取 PDF。"
            case .noPages: "文件中没有可识别的页面。"
            }
        }
    }

    func recognize(_ input: OCRInput) async throws -> OCRResult {
        let payload = try await Task.detached(priority: .userInitiated) {
            switch input.kind {
            case .image:
                guard
                    let source = CGImageSourceCreateWithData(input.data as CFData, nil),
                    let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
                else {
                    throw RecognitionError.invalidImage
                }
                let text = try recognizeText(in: image)
                return (text, 1)

            case .pdf:
                guard let document = PDFDocument(data: input.data) else {
                    throw RecognitionError.invalidPDF
                }
                guard document.pageCount > 0 else {
                    throw RecognitionError.noPages
                }

                var pages: [String] = []
                pages.reserveCapacity(document.pageCount)

                for index in 0..<document.pageCount {
                    guard let page = document.page(at: index) else { continue }
                    let thumbnail = page.thumbnail(
                        of: CGSize(width: 1800, height: 2400),
                        for: .mediaBox
                    )
                    guard let image = thumbnail.cgImage else { continue }
                    let text = try recognizeText(in: image)
                    if !text.isEmpty {
                        pages.append(text)
                    }
                }
                return (pages.joined(separator: "\n\n"), document.pageCount)
            }
        }.value

        return OCRResult(
            text: payload.0,
            sourceName: input.displayName,
            pageCount: payload.1
        )
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
