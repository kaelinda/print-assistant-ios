import Foundation
import Observation

@MainActor
@Observable
final class DocumentLibrary {
    enum Sort: String, CaseIterable {
        case modified
        case name
        case size

        var displayName: String {
            switch self {
            case .modified: "最近修改"
            case .name: "名称"
            case .size: "大小"
            }
        }
    }

    enum SourceFilter: String, CaseIterable {
        case all
        case pdf
        case scan
        case photos
        case generated
        case files

        var displayName: String {
            switch self {
            case .all: "全部"
            case .pdf: "PDF"
            case .scan: "扫描"
            case .photos: "图片 PDF"
            case .generated: "生成"
            case .files: "导入"
            }
        }
    }

    enum LibraryError: LocalizedError {
        case emptyName
        case duplicateName
        case missingDocument

        var errorDescription: String? {
            switch self {
            case .emptyName: "文件名不能为空。"
            case .duplicateName: "已有同名文件，请使用其他名称。"
            case .missingDocument: "文件不存在或已被移动。"
            }
        }
    }

    private(set) var documents: [DocumentRecord] = []
    private(set) var persistenceError: String?

    private let rootURL: URL
    private let filesURL: URL
    private let indexURL: URL

    init(baseURL: URL? = nil) {
        rootURL = LibraryPaths.applicationRoot(baseURL: baseURL)
        filesURL = LibraryPaths.filesDirectory(baseURL: baseURL)
        indexURL = LibraryPaths.indexURL(baseURL: baseURL)
        load()
    }

    func document(id: DocumentRecord.ID) -> DocumentRecord? {
        documents.first { $0.id == id }
    }

    func visibleDocuments(
        sort: Sort = .modified,
        source: SourceFilter = .all,
        query: String = ""
    ) -> [DocumentRecord] {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let filtered = documents.filter { document in
            let sourceMatches: Bool = switch source {
            case .all: true
            case .pdf: document.localURL.pathExtension.lowercased() == "pdf"
            case .scan: document.source == .scan
            case .photos: document.source == .photos
            case .generated: document.source == .generated
            case .files: document.source == .files
            }

            guard sourceMatches else { return false }
            guard !normalized.isEmpty else { return true }

            return document.name.localizedCaseInsensitiveContains(normalized)
                || (document.searchableText?.localizedCaseInsensitiveContains(normalized) ?? false)
        }

        return filtered.sorted { lhs, rhs in
            switch sort {
            case .modified:
                lhs.modifiedAt > rhs.modifiedAt
            case .name:
                lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            case .size:
                lhs.byteCount > rhs.byteCount
            }
        }
    }

    func add(_ document: DocumentRecord) throws {
        var document = document
        document.localURL = try ingest(document.localURL)

        let previous = documents
        documents.removeAll { $0.id == document.id }
        documents.insert(document, at: 0)

        do {
            try persist()
            persistenceError = nil
        } catch {
            documents = previous
            persistenceError = error.localizedDescription
            throw error
        }
    }

    func rename(id: DocumentRecord.ID, to requestedName: String) throws {
        guard let index = documents.firstIndex(where: { $0.id == id }) else {
            throw LibraryError.missingDocument
        }

        let trimmed = requestedName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw LibraryError.emptyName }

        let old = documents[index]
        let ext = old.localURL.pathExtension
        let base = (trimmed as NSString).deletingPathExtension
        guard !base.isEmpty else { throw LibraryError.emptyName }
        let finalName = ext.isEmpty ? base : "\(base).\(ext)"

        guard !documents.contains(where: {
            $0.id != id && $0.name.compare(finalName, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }) else {
            throw LibraryError.duplicateName
        }

        let newURL = old.localURL.deletingLastPathComponent().appending(path: finalName)
        guard FileManager.default.fileExists(atPath: old.localURL.path) else {
            throw LibraryError.missingDocument
        }
        guard !FileManager.default.fileExists(atPath: newURL.path) || newURL == old.localURL else {
            throw LibraryError.duplicateName
        }

        if newURL != old.localURL {
            try FileManager.default.moveItem(at: old.localURL, to: newURL)
        }

        var updated = old
        updated.name = finalName
        updated.localURL = newURL
        updated.modifiedAt = .now
        documents[index] = updated

        do {
            try persist()
            persistenceError = nil
        } catch {
            if newURL != old.localURL {
                try? FileManager.default.moveItem(at: newURL, to: old.localURL)
            }
            documents[index] = old
            persistenceError = error.localizedDescription
            throw error
        }
    }

    func updateSearchableText(id: DocumentRecord.ID, text: String?) throws {
        guard let index = documents.firstIndex(where: { $0.id == id }) else {
            throw LibraryError.missingDocument
        }

        let previous = documents[index]
        documents[index].searchableText = text
        documents[index].hasOCRText = !(text?.isEmpty ?? true)
        documents[index].modifiedAt = .now

        do {
            try persist()
            persistenceError = nil
        } catch {
            documents[index] = previous
            persistenceError = error.localizedDescription
            throw error
        }
    }

    func setPasswordProtection(id: DocumentRecord.ID, isProtected: Bool) throws {
        guard let index = documents.firstIndex(where: { $0.id == id }) else {
            throw LibraryError.missingDocument
        }
        guard documents[index].isPasswordProtected != isProtected else { return }

        let previous = documents[index]
        documents[index].isPasswordProtected = isProtected

        do {
            try persist()
            persistenceError = nil
        } catch {
            documents[index] = previous
            persistenceError = error.localizedDescription
            throw error
        }
    }

    /// Clears OCR text for every document in one atomic index write.
    /// File modification dates stay unchanged.
    func clearSearchableText() throws {
        let previous = documents
        var changed = false
        for index in documents.indices {
            guard documents[index].searchableText != nil || documents[index].hasOCRText else { continue }
            documents[index].searchableText = nil
            documents[index].hasOCRText = false
            changed = true
        }
        guard changed else { return }

        do {
            try persist()
            persistenceError = nil
        } catch {
            documents = previous
            persistenceError = error.localizedDescription
            throw error
        }
    }

    func delete(id: DocumentRecord.ID) throws {
        guard let index = documents.firstIndex(where: { $0.id == id }) else { return }
        let record = documents[index]
        let previous = documents

        let fileExists = FileManager.default.fileExists(atPath: record.localURL.path)
        let stagedURL = record.localURL
            .deletingLastPathComponent()
            .appending(path: ".deleting-\(record.id.uuidString)-\(record.localURL.lastPathComponent)")

        if fileExists {
            try FileManager.default.moveItem(at: record.localURL, to: stagedURL)
        }

        documents.remove(at: index)

        do {
            try persist()
            if fileExists {
                try FileManager.default.removeItem(at: stagedURL)
            }
            persistenceError = nil
        } catch {
            documents = previous
            if fileExists && FileManager.default.fileExists(atPath: stagedURL.path) {
                try? FileManager.default.moveItem(at: stagedURL, to: record.localURL)
            }
            try? persist()
            persistenceError = error.localizedDescription
            throw error
        }
    }

    private func ingest(_ url: URL) throws -> URL {
        if LibraryPaths.isInsideLibrary(url, root: rootURL) {
            return url.standardizedFileURL
        }

        try FileManager.default.createDirectory(at: filesURL, withIntermediateDirectories: true)
        let destination = filesURL.appending(
            path: "\(UUID().uuidString)-\(sanitizedFileName(url.lastPathComponent))",
            directoryHint: .notDirectory
        )
        try FileManager.default.copyItem(at: url, to: destination)
        try? FileManager.default.setAttributes(
            [.protectionKey: FileProtectionType.complete],
            ofItemAtPath: destination.path
        )
        return destination
    }

    private func sanitizedFileName(_ name: String) -> String {
        let base = (name as NSString).lastPathComponent
        let sanitized = base
            .replacingOccurrences(of: "/", with: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return sanitized.isEmpty ? "文件" : sanitized
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: indexURL.path) else { return }

        do {
            let data = try Data(contentsOf: indexURL)
            let decoder = JSONDecoder()
            decoder.userInfo[.printAssistantLibraryRoot] = rootURL
            let decoded = try decoder.decode([DocumentRecord].self, from: data)
            var resolved: [DocumentRecord] = []
            var needsRewrite = false
            resolved.reserveCapacity(decoded.count)

            for record in decoded {
                switch resolve(record) {
                case .ready(let document):
                    resolved.append(document)
                case .migrated(let document):
                    resolved.append(document)
                    needsRewrite = true
                case .missing:
                    needsRewrite = true
                }
            }

            documents = resolved
            if needsRewrite {
                do {
                    try persist()
                    persistenceError = nil
                } catch {
                    persistenceError = error.localizedDescription
                }
            } else {
                try FileManager.default.setAttributes(
                    [.protectionKey: FileProtectionType.complete],
                    ofItemAtPath: indexURL.path
                )
                persistenceError = nil
            }
        } catch {
            documents = []
            backupCorruptIndex()
            persistenceError = "文件库索引已损坏，原文件已备份，未写入空索引。"
        }
    }

    private enum ResolveResult {
        case ready(DocumentRecord)
        case migrated(DocumentRecord)
        case missing
    }

    private func resolve(_ record: DocumentRecord) -> ResolveResult {
        if FileManager.default.fileExists(atPath: record.localURL.path) {
            if LibraryPaths.isInsideLibrary(record.localURL, root: rootURL) {
                return .ready(record)
            }
            if let copied = try? ingest(record.localURL) {
                var migrated = record
                migrated.localURL = copied
                return .migrated(migrated)
            }
            return .ready(record)
        }

        let path = record.localURL.path
        if let marker = path.range(of: "/PrintAssistant/") {
            let relative = String(path[marker.upperBound...])
            let candidate = LibraryPaths.url(relativePath: relative, root: rootURL)
            if FileManager.default.fileExists(atPath: candidate.path) {
                var migrated = record
                migrated.localURL = candidate
                return .migrated(migrated)
            }
        }

        return .missing
    }

    /// Moves a corrupt index aside. Does not write a replacement.
    private func backupCorruptIndex() {
        let stamp = ISO8601DateFormatter().string(from: .now)
            .replacingOccurrences(of: ":", with: "-")
        var backup = indexURL.deletingLastPathComponent()
            .appending(path: "documents.json.corrupt-\(stamp)", directoryHint: .notDirectory)
        if FileManager.default.fileExists(atPath: backup.path) {
            backup = indexURL.deletingLastPathComponent()
                .appending(path: "documents.json.corrupt-\(stamp)-\(UUID().uuidString)", directoryHint: .notDirectory)
        }
        try? FileManager.default.moveItem(at: indexURL, to: backup)
    }

    private func persist() throws {
        let encoder = JSONEncoder()
        encoder.userInfo[.printAssistantLibraryRoot] = rootURL
        let data = try encoder.encode(documents)
        try data.write(to: indexURL, options: [.atomic])
        try FileManager.default.setAttributes(
            [.protectionKey: FileProtectionType.complete],
            ofItemAtPath: indexURL.path
        )
    }
}
