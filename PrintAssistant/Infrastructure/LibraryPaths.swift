import Foundation

enum LibraryPaths {
    /// `Application Support/PrintAssistant`, or `baseURL/PrintAssistant` in tests.
    static func applicationRoot(baseURL: URL? = nil) -> URL {
        let root: URL
        if let baseURL {
            root = baseURL
        } else if let support = try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ) {
            root = support
        } else {
            root = FileManager.default.temporaryDirectory
                .appending(path: "PrintAssistantFallback", directoryHint: .isDirectory)
        }

        let directory = root.appending(path: "PrintAssistant", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    /// Persistent imported and generated files: `Application Support/PrintAssistant/Documents`.
    static func filesDirectory(baseURL: URL? = nil) -> URL {
        let directory = applicationRoot(baseURL: baseURL)
            .appending(path: "Documents", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    static func indexURL(baseURL: URL? = nil) -> URL {
        applicationRoot(baseURL: baseURL)
            .appending(path: "documents.json", directoryHint: .notDirectory)
    }

    static func url(relativePath: String, root: URL) -> URL {
        relativePath.split(separator: "/").reduce(root) { partial, component in
            partial.appending(path: String(component), directoryHint: .notDirectory)
        }
    }

    static func relativePath(for url: URL, root: URL) -> String? {
        let rootPath = root.standardizedFileURL.path
        let path = url.standardizedFileURL.path
        let prefix = rootPath.hasSuffix("/") ? rootPath : rootPath + "/"
        guard path.hasPrefix(prefix) else { return nil }
        return String(path.dropFirst(prefix.count))
    }

    static func isInsideLibrary(_ url: URL, root: URL) -> Bool {
        relativePath(for: url, root: root) != nil
    }
}

extension CodingUserInfoKey {
    static let printAssistantLibraryRoot = CodingUserInfoKey(rawValue: "printAssistantLibraryRoot")!
}
