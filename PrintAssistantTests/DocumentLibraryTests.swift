import Foundation
import Testing
@testable import PrintAssistant

@MainActor
struct DocumentLibraryTests {
    @Test
    func persistsAndReloadsDocumentMetadata() throws {
        let root = FileManager.default.temporaryDirectory
            .appending(path: "PrintAssistantTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let file = root.appending(path: "sample.pdf", directoryHint: .notDirectory)
        try Data("%PDF-test".utf8).write(to: file)

        let record = DocumentRecord(
            name: "sample.pdf",
            pageCount: 1,
            byteCount: 9,
            source: .scan,
            localURL: file
        )

        let first = DocumentLibrary(baseURL: root)
        try first.add(record)
        #expect(first.documents.map(\.id) == [record.id])

        let reloaded = DocumentLibrary(baseURL: root)
        #expect(reloaded.documents.count == 1)
        #expect(reloaded.documents.first?.id == record.id)
        #expect(reloaded.documents.first?.name == "sample.pdf")
    }

    @Test
    func unicodeFilenameSurvivesRelaunch() throws {
        let root = FileManager.default.temporaryDirectory
            .appending(path: "PrintAssistantUnicode-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let file = root.appending(path: "扫描文档-合同.pdf", directoryHint: .notDirectory)
        try Data("%PDF-unicode".utf8).write(to: file)

        let record = DocumentRecord(
            name: "扫描文档-合同.pdf",
            pageCount: 1,
            byteCount: 12,
            source: .scan,
            localURL: file
        )

        let first = DocumentLibrary(baseURL: root)
        try first.add(record)

        #expect(FileManager.default.fileExists(atPath: file.path))

        let reloaded = DocumentLibrary(baseURL: root)
        #expect(reloaded.document(id: record.id)?.name == "扫描文档-合同.pdf")
    }
}

