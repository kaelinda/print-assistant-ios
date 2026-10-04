import Foundation
import Observation

@MainActor
@Observable
final class DocumentLibrary {
    private(set) var documents: [DocumentRecord] = []

    func document(id: DocumentRecord.ID) -> DocumentRecord? {
        documents.first { $0.id == id }
    }

    func add(_ document: DocumentRecord) {
        documents.removeAll { $0.id == document.id }
        documents.insert(document, at: 0)
    }

    func delete(id: DocumentRecord.ID) throws {
        guard let index = documents.firstIndex(where: { $0.id == id }) else { return }
        let record = documents[index]
        if FileManager.default.fileExists(atPath: record.localURL.path()) {
            try FileManager.default.removeItem(at: record.localURL)
        }
        documents.remove(at: index)
    }
}
