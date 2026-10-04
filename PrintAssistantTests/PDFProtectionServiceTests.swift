import Foundation
import PDFKit
import Testing
import UIKit
@testable import PrintAssistant

struct PDFProtectionServiceTests {
    @Test
    func protectsPDFAndPreservesSource() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanup() }

        let source = try fixture.makePDF(name: "source.pdf")
        let before = try Data(contentsOf: source)

        let output = try await fixture.service.protect(
            .init(
                sourceURL: source,
                userPassword: "reader-secret",
                ownerPassword: "owner-secret"
            ),
            filename: "protected.pdf"
        )

        let document = try #require(PDFDocument(url: output))
        #expect(document.isLocked)
        #expect(document.unlock(withPassword: "reader-secret"))
        #expect(document.pageCount == 2)
        #expect(try Data(contentsOf: source) == before)
    }

    @Test
    func removesProtectionOnlyWithCorrectPassword() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanup() }

        let source = try fixture.makePDF(name: "source.pdf")
        let protected = try await fixture.service.protect(
            .init(
                sourceURL: source,
                userPassword: "reader-secret",
                ownerPassword: "owner-secret"
            ),
            filename: "protected.pdf"
        )

        await #expect(throws: PDFProtectionService.ProtectionError.self) {
            _ = try await fixture.service.removeProtection(
                sourceURL: protected,
                password: "wrong",
                filename: "wrong.pdf"
            )
        }

        let unlocked = try await fixture.service.removeProtection(
            sourceURL: protected,
            password: "reader-secret",
            filename: "unlocked.pdf"
        )
        let document = try #require(PDFDocument(url: unlocked))
        #expect(!document.isLocked)
        #expect(document.pageCount == 2)
    }

    @Test
    func refusesToOverwriteSource() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanup() }

        let source = try fixture.makePDF(name: "source.pdf")

        await #expect(throws: PDFProtectionService.ProtectionError.self) {
            _ = try await fixture.service.protect(
                .init(
                    sourceURL: source,
                    userPassword: "reader",
                    ownerPassword: "owner"
                ),
                filename: "source.pdf"
            )
        }
    }

    private final class Fixture {
        let root: URL
        let service: PDFProtectionService

        init() throws {
            root = FileManager.default.temporaryDirectory
                .appending(path: "PDFProtectionTests-\(UUID().uuidString)", directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            service = PDFProtectionService(outputDirectory: root)
        }

        func makePDF(name: String) throws -> URL {
            let document = PDFDocument()
            for width: CGFloat in [100, 120] {
                let image = UIGraphicsImageRenderer(size: CGSize(width: width, height: 200)).image { context in
                    UIColor.white.setFill()
                    context.cgContext.fill(CGRect(x: 0, y: 0, width: width, height: 200))
                }
                document.insert(try #require(PDFPage(image: image)), at: document.pageCount)
            }
            let url = root.appending(path: name)
            #expect(document.write(to: url))
            return url
        }

        func cleanup() {
            try? FileManager.default.removeItem(at: root)
        }
    }
}
