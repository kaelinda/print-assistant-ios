import Foundation

struct PDFImportService: Sendable {
    enum ImportError: LocalizedError {
        case noFiles
        case unableToStage

        var errorDescription: String? {
            switch self {
            case .noFiles: "没有选择 PDF 文件。"
            case .unableToStage: "无法读取所选 PDF 文件。"
            }
        }
    }

    func stage(urls: [URL]) async throws -> [PDFSourceItem] {
        guard !urls.isEmpty else { throw ImportError.noFiles }

        return try await Task.detached(priority: .userInitiated) {
            let root = FileManager.default.temporaryDirectory
                .appending(path: "PrintAssistant-PDFImports", directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

            var staged: [PDFSourceItem] = []
            do {
                for source in urls {
                    let accessed = source.startAccessingSecurityScopedResource()
                    defer {
                        if accessed { source.stopAccessingSecurityScopedResource() }
                    }

                    let destination = root.appending(
                        path: "\(UUID().uuidString)-\(source.lastPathComponent)",
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
}
