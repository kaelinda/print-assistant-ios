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

    @Test
    func storesRelativePathsAndSurvivesLibraryRootMove() throws {
        let fixture = try Fixture()
        defer { fixture.cleanup() }

        let record = try fixture.add(name: "sample.pdf", source: .files)
        let index = fixture.root.appending(path: "PrintAssistant/documents.json", directoryHint: .notDirectory)
        let json = try String(contentsOf: index, encoding: .utf8)

        #expect(json.contains("Documents/"))
        #expect(!json.contains(fixture.root.path))

        let movedRoot = FileManager.default.temporaryDirectory
            .appending(path: "PrintAssistantMoved-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: movedRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: movedRoot) }
        try FileManager.default.copyItem(
            at: fixture.root.appending(path: "PrintAssistant", directoryHint: .isDirectory),
            to: movedRoot.appending(path: "PrintAssistant", directoryHint: .isDirectory)
        )

        let reloaded = DocumentLibrary(baseURL: movedRoot)
        let stored = try #require(reloaded.document(id: record.id))
        #expect(stored.name == "sample.pdf")
        #expect(FileManager.default.fileExists(atPath: stored.localURL.path))
        #expect(stored.localURL.path.hasPrefix(movedRoot.path))
    }

    @Test
    func corruptIndexIsBackedUpAndNotReplacedWithEmptyLibrary() throws {
        let root = FileManager.default.temporaryDirectory
            .appending(path: "PrintAssistantCorrupt-\(UUID().uuidString)", directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: root) }

        _ = DocumentLibrary(baseURL: root)
        let index = root.appending(path: "PrintAssistant/documents.json", directoryHint: .notDirectory)
        let corrupt = Data("not-json".utf8)
        try corrupt.write(to: index)

        let broken = DocumentLibrary(baseURL: root)
        #expect(broken.documents.isEmpty)
        #expect(broken.persistenceError != nil)
        #expect(!FileManager.default.fileExists(atPath: index.path))

        let directory = index.deletingLastPathComponent()
        let backups = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        let backup = try #require(backups.first { $0.lastPathComponent.hasPrefix("documents.json.corrupt-") })
        #expect(try Data(contentsOf: backup) == corrupt)
        #expect(!FileManager.default.fileExists(atPath: index.path))
    }

    @Test
    func clearSearchableTextIsAtomicAndKeepsModifiedDate() throws {
        let fixture = try Fixture()
        defer { fixture.cleanup() }

        let record = try fixture.add(name: "notes.pdf", source: .scan)
        try fixture.library.updateSearchableText(id: record.id, text: "发票 128")
        let before = try #require(fixture.library.document(id: record.id)).modifiedAt

        try fixture.library.clearSearchableText()

        let cleared = try #require(fixture.library.document(id: record.id))
        #expect(cleared.searchableText == nil)
        #expect(cleared.hasOCRText == false)
        #expect(cleared.modifiedAt == before)

        let reloaded = DocumentLibrary(baseURL: fixture.root)
        let stored = try #require(reloaded.document(id: record.id))
        #expect(stored.searchableText == nil)
        #expect(stored.hasOCRText == false)
        #expect(stored.modifiedAt == before)
    }

    @Test
    func pdfFilterMatchesExtensionAndImportSourceStaysSeparate() throws {
        let fixture = try Fixture()
        defer { fixture.cleanup() }

        let scan = try fixture.add(name: "扫描件.pdf", source: .scan)
        let imported = try fixture.add(name: "外部.pdf", source: .files)
        let note = try fixture.add(name: "备注.txt", source: .generated)

        let pdfs = fixture.library.visibleDocuments(source: .pdf)
        #expect(Set(pdfs.map(\.id)) == Set([scan.id, imported.id]))
        #expect(!pdfs.map(\.id).contains(note.id))

        let imports = fixture.library.visibleDocuments(source: .files)
        #expect(imports.map(\.id) == [imported.id])
    }

    @Test
    func passwordProtectionFlagDoesNotBumpModifiedDate() throws {
        let fixture = try Fixture()
        defer { fixture.cleanup() }

        let record = try fixture.add(name: "secret.pdf", source: .files)
        let before = record.modifiedAt
        try fixture.library.setPasswordProtection(id: record.id, isProtected: true)

        let updated = try #require(fixture.library.document(id: record.id))
        #expect(updated.isPasswordProtected)
        #expect(updated.modifiedAt == before)

        let reloaded = DocumentLibrary(baseURL: fixture.root)
        #expect(reloaded.document(id: record.id)?.isPasswordProtected == true)
        #expect(reloaded.document(id: record.id)?.modifiedAt == before)
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
            return try #require(library.document(id: record.id))
        }

        func cleanup() {
            try? FileManager.default.removeItem(at: root)
        }
    }
}
