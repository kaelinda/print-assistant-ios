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
        case scan
        case photos
        case generated
        case files

        var displayName: String {
            switch self {
            case .all: "全部"
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

    private let indexURL: URL

    init(baseURL: URL? = nil) {
        let root: URL
        if let baseURL {
            root = baseURL
        } else {
            root = (try? FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )) ?? FileManager.default.temporaryDirectory
        }

        let directory = root.appending(path: "PrintAssistant", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        indexURL = directory.appending(path: "documents.json", directoryHint: .notDirectory)
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
        guard FileManager.default.fileExists(atPath: old.localURL.path()) else {
            throw LibraryError.missingDocument
        }
        guard !FileManager.default.fileExists(atPath: newURL.path()) || newURL == old.localURL else {
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

    func delete(id: DocumentRecord.ID) throws {
        guard let index = documents.firstIndex(where: { $0.id == id }) else { return }
        let record = documents[index]
        let previous = documents

        let fileExists = FileManager.default.fileExists(atPath: record.localURL.path())
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
            if fileExists && FileManager.default.fileExists(atPath: stagedURL.path()) {
                try? FileManager.default.moveItem(at: stagedURL, to: record.localURL)
            }
            try? persist()
            persistenceError = error.localizedDescription
            throw error
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: indexURL.path()) else { return }

        do {
            let data = try Data(contentsOf: indexURL)
            let decoded = try JSONDecoder().decode([DocumentRecord].self, from: data)
            documents = decoded.filter { FileManager.default.fileExists(atPath: $0.localURL.path()) }
            if documents.count != decoded.count {
                try persist()
            } else {
                try FileManager.default.setAttributes(
                    [.protectionKey: FileProtectionType.complete],
                    ofItemAtPath: indexURL.path()
                )
            }
            persistenceError = nil
        } catch {
            documents = []
            persistenceError = error.localizedDescription
        }
    }

    private func persist() throws {
        let data = try JSONEncoder().encode(documents)
        try data.write(to: indexURL, options: [.atomic])
        try FileManager.default.setAttributes(
            [.protectionKey: FileProtectionType.complete],
            ofItemAtPath: indexURL.path()
        )
    }
}
