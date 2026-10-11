import Foundation
import Testing
@testable import PrintAssistant

struct PDFImportServiceTests {
    @Test
    func copiesIntoPersistentDirectoryWithoutMutatingSource() async throws {
        let root = FileManager.default.temporaryDirectory
            .appending(path: "PDFImportTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        let sourceDirectory = root.appending(path: "source", directoryHint: .isDirectory)
        let libraryDirectory = root.appending(path: "Application Support/PrintAssistant/Documents", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: sourceDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let source = sourceDirectory.appending(path: "source.pdf")
        let original = Data("%PDF-test-source".utf8)
        try original.write(to: source)

        let service = PDFImportService(filesDirectory: libraryDirectory)
        let items = try await service.copyIntoLibrary(urls: [source])
        defer { service.cleanup(items) }

        let item = try #require(items.first)
        #expect(item.isTemporary)
        #expect(item.displayName == "source.pdf")
        #expect(item.url.deletingLastPathComponent().standardizedFileURL == libraryDirectory.standardizedFileURL)
        #expect(!item.url.path.contains("PrintAssistant-PDFImports"))
        #expect(FileManager.default.fileExists(atPath: item.url.path))
        #expect(try Data(contentsOf: source) == original)
        #expect(try Data(contentsOf: item.url) == original)
    }
}
