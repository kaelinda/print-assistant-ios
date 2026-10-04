import Foundation
import Testing
@testable import PrintAssistant

struct PDFImportServiceTests {
    @Test
    func stagingCopiesInputWithoutMutatingSource() async throws {
        let root = FileManager.default.temporaryDirectory
            .appending(path: "PDFImportTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let source = root.appending(path: "source.pdf")
        let original = Data("%PDF-test-source".utf8)
        try original.write(to: source)

        let service = PDFImportService()
        let items = try await service.stage(urls: [source])
        defer { service.cleanup(items) }

        let item = try #require(items.first)
        #expect(item.isTemporary)
        #expect(item.displayName == "source.pdf")
        #expect(item.url != source)
        #expect(FileManager.default.fileExists(atPath: item.url.path()))
        #expect(try Data(contentsOf: source) == original)
        #expect(try Data(contentsOf: item.url) == original)
    }
}
