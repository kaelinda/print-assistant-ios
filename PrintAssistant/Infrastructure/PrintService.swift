import PDFKit
import UIKit

@MainActor
enum PrintService {
    static func present(
        url: URL,
        jobName: String,
        template: PrintTemplate? = nil,
        onFailure: ((String) -> Void)? = nil
    ) {
        Task { @MainActor in
            let item: URL
            do {
                item = try await preparedURLForPresentation(source: url, template: template)
            } catch {
                onFailure?(error.localizedDescription)
                return
            }

            let controller = UIPrintInteractionController.shared
            let info = UIPrintInfo.printInfo()
            info.jobName = jobName
            info.outputType = .general
            if let template {
                let paper = PrintLayout.paperSize(named: template.paper)
                info.orientation = paper.width > paper.height ? .landscape : .portrait
            }
            controller.printInfo = info
            controller.printingItem = item
            controller.present(animated: true)
        }
    }

    static func preparedURL(for source: URL, template: PrintTemplate?) throws -> URL {
        guard let template else { return source }
        pruneSpoolDirectory()
        return try PrintTemplateRenderer.render(sourceURL: source, template: template)
    }

    private static func preparedURLForPresentation(
        source: URL,
        template: PrintTemplate?
    ) async throws -> URL {
        guard let template else { return source }
        pruneSpoolDirectory()
        let task = Task.detached(priority: .userInitiated) {
            try Task.checkCancellation()
            return try PrintTemplateRenderer.render(sourceURL: source, template: template)
        }
        return try await withTaskCancellationHandler {
            try await task.value
        } onCancel: {
            task.cancel()
        }
    }

    /// Keeps failed or abandoned print jobs from accumulating indefinitely.
    /// The source document remains in the persistent library; only generated
    /// spool files older than one day are removed.
    static func pruneSpoolDirectory(now: Date = .now) {
        let directory = LibraryPaths.applicationRoot()
            .appending(path: "PrintJobs", directoryHint: .isDirectory)
        guard let items = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey]
        ) else { return }

        let cutoff = now.addingTimeInterval(-24 * 60 * 60)
        for item in items {
            guard
                item.pathExtension.lowercased() == "pdf",
                let values = try? item.resourceValues(forKeys: [.contentModificationDateKey, .isRegularFileKey]),
                values.isRegularFile == true,
                let modified = values.contentModificationDate,
                modified < cutoff
            else { continue }
            try? FileManager.default.removeItem(at: item)
        }
    }
}

enum PrintTemplateRenderer {
    enum RenderError: LocalizedError {
        case unreadablePDF
        case lockedPDF
        case unableToWrite

        var errorDescription: String? {
            switch self {
            case .unreadablePDF: String(localized: "无法读取要打印的 PDF。")
            case .lockedPDF: String(localized: "PDF 已加密，请先解锁后再打印。")
            case .unableToWrite: String(localized: "无法生成打印版 PDF，请重试。")
            }
        }
    }

    static func render(sourceURL: URL, template: PrintTemplate, outputDirectory: URL? = nil) throws -> URL {
        guard let source = PDFDocument(url: sourceURL) else {
            throw RenderError.unreadablePDF
        }
        guard !source.isLocked else { throw RenderError.lockedPDF }
        guard source.pageCount > 0 else { throw RenderError.unreadablePDF }

        let layout = PrintLayout(template: template)
        let directory = outputDirectory ?? spoolDirectory()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appending(
            path: "\(String(localized: "打印"))-\(UUID().uuidString).pdf",
            directoryHint: .notDirectory
        )
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: layout.paperSize))

        do {
            try renderer.writePDF(to: url) { context in
                for _ in 0..<layout.copies {
                    for index in 0..<source.pageCount {
                        guard let page = source.page(at: index) else { continue }
                        context.beginPage()
                        let destination = PrintLayout.destinationRect(
                            pageSize: page.bounds(for: .mediaBox).size,
                            paperSize: layout.paperSize,
                            marginPoints: layout.marginPoints,
                            scale: layout.scale
                        )
                        draw(page, in: destination, context: context.cgContext)
                    }
                }
            }
        } catch {
            try? FileManager.default.removeItem(at: url)
            throw RenderError.unableToWrite
        }

        guard let written = PDFDocument(url: url), written.pageCount == source.pageCount * layout.copies else {
            try? FileManager.default.removeItem(at: url)
            throw RenderError.unableToWrite
        }
        try? FileManager.default.setAttributes(
            [.protectionKey: FileProtectionType.complete],
            ofItemAtPath: url.path
        )
        return url
    }

    private static func draw(_ page: PDFPage, in rect: CGRect, context: CGContext) {
        let bounds = page.bounds(for: .mediaBox)
        guard bounds.width > 0, bounds.height > 0 else { return }
        context.saveGState()
        context.translateBy(x: rect.origin.x, y: rect.origin.y + rect.height)
        context.scaleBy(x: rect.width / bounds.width, y: -rect.height / bounds.height)
        page.draw(with: .mediaBox, to: context)
        context.restoreGState()
    }

    private static func spoolDirectory() -> URL {
        let directory = LibraryPaths.applicationRoot()
            .appending(path: "PrintJobs", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
