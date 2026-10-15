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
        try Task.checkCancellation()
        let directory = filesDirectory ?? LibraryPaths.filesDirectory()

        let task = Task.detached(priority: .userInitiated) {
            try Task.checkCancellation()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

            var staged: [PDFSourceItem] = []
            var currentDestination: URL?
            do {
                for source in urls {
                    try Task.checkCancellation()
                    let destination = directory.appending(
                        path: Self.uniqueFileName(for: source.lastPathComponent),
                        directoryHint: .notDirectory
                    )
                    currentDestination = destination
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
                    currentDestination = nil
                }
                return staged
            } catch {
                for item in staged {
                    try? FileManager.default.removeItem(at: item.url)
                }
                if let currentDestination {
                    try? FileManager.default.removeItem(at: currentDestination)
                }
                if error is CancellationError {
                    throw error
                }
                throw ImportError.unableToStage
            }
        }
        return try await withTaskCancellationHandler {
            try await task.value
        } onCancel: {
            task.cancel()
        }
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
