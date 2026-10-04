import Foundation
import Testing
@testable import PrintAssistant

@MainActor
struct DocumentLibraryTests {
    @Test
    func persistsAndReloadsDocumentMetadata() throws {
        let fixture = try Fixture()
        defer { fixture.cleanup() }

        let record = try fixture.add(name: "sample.pdf", source: .scan)
        let reloaded = DocumentLibrary(baseURL: fixture.root)

        #expect(reloaded.documents.count == 1)
        #expect(reloaded.documents.first?.id == record.id)
        #expect(reloaded.documents.first?.name == "sample.pdf")
    }

    @Test
    func renameMovesPhysicalFileAndPersistsIdentity() throws {
        let fixture = try Fixture()
        defer { fixture.cleanup() }

        let record = try fixture.add(name: "old.pdf", source: .scan)
        let oldURL = record.localURL

        try fixture.library.rename(id: record.id, to: "合同")

        let renamed = try #require(fixture.library.document(id: record.id))
        #expect(renamed.id == record.id)
        #expect(renamed.name == "合同.pdf")
        #expect(!FileManager.default.fileExists(atPath: oldURL.path))
        #expect(FileManager.default.fileExists(atPath: renamed.localURL.path))

        let reloaded = DocumentLibrary(baseURL: fixture.root)
        #expect(reloaded.document(id: record.id)?.name == "合同.pdf")
    }

    @Test
    func duplicateRenameIsRejected() throws {
        let fixture = try Fixture()
        defer { fixture.cleanup() }

        let first = try fixture.add(name: "first.pdf", source: .scan)
        _ = try fixture.add(name: "second.pdf", source: .photos)

        #expect(throws: DocumentLibrary.LibraryError.self) {
            try fixture.library.rename(id: first.id, to: "second")
        }

        #expect(fixture.library.document(id: first.id)?.name == "first.pdf")
    }

    @Test
    func searchMatchesFilenameAndOCRTextWithoutChangingIdentity() throws {
        let fixture = try Fixture()
        defer { fixture.cleanup() }

        let contract = try fixture.add(name: "租赁合同.pdf", source: .scan)
        let receipt = try fixture.add(name: "receipt.pdf", source: .photos)
        try fixture.library.updateSearchableText(id: receipt.id, text: "杭州餐饮发票 合计 128 元")

        let byName = fixture.library.visibleDocuments(query: "租赁")
        #expect(byName.map(\.id) == [contract.id])

        let byOCR = fixture.library.visibleDocuments(query: "128")
        #expect(byOCR.map(\.id) == [receipt.id])
    }

    @Test
    func OCRIndexPersistsAcrossRelaunch() throws {
        let fixture = try Fixture()
        defer { fixture.cleanup() }

        let record = try fixture.add(name: "contract.pdf", source: .scan)
        try fixture.library.updateSearchableText(id: record.id, text: "房屋租赁合同 月租金 6800 元")

        let reloaded = DocumentLibrary(baseURL: fixture.root)
        let results = reloaded.visibleDocuments(query: "6800")

        #expect(results.map(\.id) == [record.id])
        #expect(reloaded.document(id: record.id)?.hasOCRText == true)
    }

    @Test
    func deleteRemovesFileAndDoesNotReappearAfterRelaunch() throws {
        let fixture = try Fixture()
        defer { fixture.cleanup() }

        let record = try fixture.add(name: "delete-me.pdf", source: .scan)
        #expect(FileManager.default.fileExists(atPath: record.localURL.path))

        try fixture.library.delete(id: record.id)

        #expect(!FileManager.default.fileExists(atPath: record.localURL.path))
        #expect(fixture.library.document(id: record.id) == nil)

        let reloaded = DocumentLibrary(baseURL: fixture.root)
        #expect(reloaded.document(id: record.id) == nil)
    }

    @Test
    func sourceFilterAndSortPreserveDocumentIDs() throws {
        let fixture = try Fixture()
        defer { fixture.cleanup() }

        let scan = try fixture.add(name: "z.pdf", source: .scan, byteCount: 100)
        let photo = try fixture.add(name: "a.pdf", source: .photos, byteCount: 900)

        let photos = fixture.library.visibleDocuments(sort: .name, source: .photos)
        #expect(photos.map(\.id) == [photo.id])

        let bySize = fixture.library.visibleDocuments(sort: .size)
        #expect(bySize.first?.id == photo.id)
        #expect(Set(bySize.map(\.id)) == Set([scan.id, photo.id]))
    }

    @MainActor
    private final class Fixture {
        let root: URL
        let library: DocumentLibrary

        init() throws {
            root = FileManager.default.temporaryDirectory
                .appending(path: "PrintAssistantTests-\(UUID().uuidString)", directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            library = DocumentLibrary(baseURL: root)
        }

        func add(
            name: String,
            source: DocumentRecord.Source,
            byteCount: Int64 = 9
        ) throws -> DocumentRecord {
            let file = root.appending(path: name, directoryHint: .notDirectory)
            try Data("%PDF-test".utf8).write(to: file)

            let record = DocumentRecord(
                name: name,
                pageCount: 1,
                byteCount: byteCount,
                source: source,
                localURL: file
            )
            try library.add(record)
            return record
        }

        func cleanup() {
            try? FileManager.default.removeItem(at: root)
        }
    }
}
