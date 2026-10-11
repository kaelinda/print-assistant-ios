import Foundation

/// Starts security-scoped access before the file-picker callback returns.
struct SecurityScopedAccess: Sendable {
    let urls: [URL]
    private let started: [Bool]

    init(result: Result<[URL], Error>) throws {
        let urls = try result.get()
        guard !urls.isEmpty else {
            throw PDFImportService.ImportError.noFiles
        }
        self.urls = urls
        self.started = urls.map { $0.startAccessingSecurityScopedResource() }
    }

    func stop() {
        for (url, didStart) in zip(urls, started) where didStart {
            url.stopAccessingSecurityScopedResource()
        }
    }
}
