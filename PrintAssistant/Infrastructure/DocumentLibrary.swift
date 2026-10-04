import Foundation
import Observation

@MainActor
@Observable
final class DocumentLibrary {
    enum LibraryError: Error {
        case unableToCreateStorage
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

    func delete(id: DocumentRecord.ID) throws {
        guard let index = documents.firstIndex(where: { $0.id == id }) else { return }
        let record = documents[index]
        let previous = documents
        documents.remove(at: index)

        do {
            try persist()
            if FileManager.default.fileExists(atPath: record.localURL.path()) {
                try FileManager.default.removeItem(at: record.localURL)
            }
            persistenceError = nil
        } catch {
            documents = previous
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
    }
}
