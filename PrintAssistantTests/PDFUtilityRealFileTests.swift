import Foundation
import PDFKit
import Testing
import UIKit
@testable import PrintAssistant

@MainActor
struct PDFUtilityRealFileTests {
    @Test
    func encryptionRecoveryAndPersistentLibraryUseRealUnicodePDFs() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanup() }

        let original = try fixture.makePDF("合同原件.pdf")
        let sourceBytes = try Data(contentsOf: original)
        let protection = PDFProtectionService(outputDirectory: fixture.output)

        let encrypted = try await protection.protect(
            .init(sourceURL: original, userPassword: "reader-secret", ownerPassword: "owner-secret"),
            filename: "合同加密.pdf"
        )
        let locked = try #require(PDFDocument(url: encrypted))
        #expect(locked.isLocked)

        await #expect(throws: PDFProtectionService.ProtectionError.self) {
            _ = try await protection.removeProtection(
                sourceURL: encrypted, password: "incorrect", filename: "不应生成.pdf"
            )
        }
        #expect(!FileManager.default.fileExists(
            atPath: fixture.output.appending(path: "不应生成.pdf").path
        ))

        let decrypted = try await protection.removeProtection(
            sourceURL: encrypted, password: "reader-secret", filename: "合同解密.pdf"
        )
        let unlocked = try #require(PDFDocument(url: decrypted))
        #expect(!unlocked.isLocked)
        #expect(unlocked.pageCount == 2)
        #expect(try Data(contentsOf: original) == sourceBytes)

        let metadata = try decrypted.resourceValues(forKeys: [.fileSizeKey])
        let record = DocumentRecord(
            name: "合同解密.pdf",
            pageCount: unlocked.pageCount,
            byteCount: Int64(metadata.fileSize ?? 0),
            source: .generated,
            localURL: decrypted
        )
        let library = DocumentLibrary(baseURL: fixture.root)
        try library.add(record)
        let relaunched = DocumentLibrary(baseURL: fixture.root)
        #expect(relaunched.document(id: record.id)?.localURL == decrypted)
        #expect(relaunched.visibleDocuments(query: "解密").map(\.id) == [record.id])
        #expect(FileManager.default.fileExists(atPath: decrypted.path))
    }

    @Test
    func compressionNeverOverwritesSourcesOrKeepsNonSmallerOutputs() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanup() }
        let fixtureURL = try fixture.makePDF("待压缩.pdf")
        let source = fixture.output.appending(path: "待压缩.pdf")
        try FileManager.default.moveItem(at: fixtureURL, to: source)
        let original = try Data(contentsOf: source)
        let compressor = PDFCompressionService(outputDirectory: fixture.output)

        await #expect(throws: PDFCompressionService.CompressionError.self) {
            _ = try await compressor.compress(
                sourceURL: source, filename: source.lastPathComponent
            )
        }

        do {
            let result = try await compressor.compress(
                sourceURL: source, filename: "压缩结果.pdf"
            )
            #expect(result.originalBytes > result.compressedBytes)
            #expect(result.savedFraction > 0)
            #expect(try #require(PDFDocument(url: result.url)).pageCount == 2)
        } catch PDFCompressionService.CompressionError.noMeaningfulSavings {
            #expect(!FileManager.default.fileExists(
                atPath: fixture.output.appending(path: "压缩结果.pdf").path
            ))
        }
        #expect(try Data(contentsOf: source) == original)
    }

    private final class Fixture {
        let root: URL
        let output: URL

        init() throws {
            root = FileManager.default.temporaryDirectory
                .appending(path: "PDFUtilityRealFileTests-\(UUID().uuidString)", directoryHint: .isDirectory)
            output = root.appending(path: "documents", directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        }

        func makePDF(_ filename: String) throws -> URL {
            let document = PDFDocument()
            for width: CGFloat in [200, 240] {
                let image = UIGraphicsImageRenderer(
                    size: CGSize(width: width, height: 320)
                ).image { context in
                    UIColor.white.setFill()
                    context.cgContext.fill(CGRect(x: 0, y: 0, width: width, height: 320))
                    UIColor.black.setFill()
                    context.cgContext.fill(CGRect(x: 12, y: 12, width: 90, height: 40))
                }
                document.insert(try #require(PDFPage(image: image)), at: document.pageCount)
            }
            let url = root.appending(path: filename)
            #expect(document.write(to: url))
            return url
        }

        func cleanup() {
            try? FileManager.default.removeItem(at: root)
        }
    }
}
