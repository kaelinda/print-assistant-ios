import Foundation

struct PDFImportService: Sendable {
    enum ImportError: LocalizedError {
        case noFiles
        case unableToStage

        var errorDescription: String? {
            switch self {
            case .noFiles: String(localized: "没有选择 PDF 文件。")
            case .unableToStage: String(localized: "无法读取所选 PDF 文件。")
            }
        }
    }

    /// Persistent destination. `nil` uses Application Support/PrintAssistant/Documents.
    var filesDirectory: URL?

    func copyIntoLibrary(urls: [URL]) async throws -> [PDFSourceItem] {
        guard !urls.isEmpty else { throw ImportError.noFiles }
        let directory = filesDirectory ?? LibraryPaths.filesDirectory()

        return try await Task.detached(priority: .userInitiated) {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

            var staged: [PDFSourceItem] = []
            do {
                for source in urls {
                    let destination = directory.appending(
                        path: Self.uniqueFileName(for: source.lastPathComponent),
                        directoryHint: .notDirectory
                    )
                    try FileManager.default.copyItem(at: source, to: destination)
                    try FileManager.default.setAttributes(
                        [.protectionKey: FileProtectionType.complete],
                        ofItemAtPath: destination.path
                    )
                    staged.append(.init(
                        url: destination,
                        displayName: source.lastPathComponent,
                        isTemporary: true
                    ))
                }
                return staged
            } catch {
                for item in staged {
                    try? FileManager.default.removeItem(at: item.url)
                }
                throw ImportError.unableToStage
            }
        }.value
    }

    func cleanup(_ items: [PDFSourceItem]) {
        for item in items where item.isTemporary {
            try? FileManager.default.removeItem(at: item.url)
        }
    }

    private static func uniqueFileName(for lastComponent: String) -> String {
        let base = (lastComponent as NSString).lastPathComponent
        let sanitized = base
            .replacingOccurrences(of: "/", with: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let name = sanitized.isEmpty ? String(localized: "导入文件") : sanitized
        return "\(UUID().uuidString)-\(name)"
    }
}
