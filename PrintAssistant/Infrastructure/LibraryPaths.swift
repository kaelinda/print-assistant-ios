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
        let pairs = [
            (url, root),
            (url.standardizedFileURL, root.standardizedFileURL),
            (url.resolvingSymlinksInPath(), root.resolvingSymlinksInPath()),
            (
                url.standardizedFileURL.resolvingSymlinksInPath(),
                root.standardizedFileURL.resolvingSymlinksInPath()
            )
        ]
        for (file, base) in pairs {
            if let relative = relativePath(filePath: file.path, rootPath: base.path) {
                return relative
            }
            if let relative = relativePath(
                filePath: stripPrivatePrefix(file.path),
                rootPath: stripPrivatePrefix(base.path)
            ) {
                return relative
            }
        }
        return nil
    }

    /// Simulator and macOS temp directories often disagree on the `/private` symlink prefix.
    private static func stripPrivatePrefix(_ path: String) -> String {
        path.hasPrefix("/private/") ? String(path.dropFirst("/private".count)) : path
    }

    private static func relativePath(filePath: String, rootPath: String) -> String? {
        let root = rootPath.hasSuffix("/") ? String(rootPath.dropLast()) : rootPath
        let prefix = root + "/"
        guard filePath.hasPrefix(prefix) else { return nil }
        let relative = String(filePath.dropFirst(prefix.count))
        return relative.isEmpty ? nil : relative
    }

    static func isInsideLibrary(_ url: URL, root: URL) -> Bool {
        relativePath(for: url, root: root) != nil
    }
}

extension CodingUserInfoKey {
    static let printAssistantLibraryRoot = CodingUserInfoKey(rawValue: "printAssistantLibraryRoot")!
}
