import Foundation
import PDFKit
import Testing
import UIKit
@testable import PrintAssistant

struct PDFCompressionServiceTests {
    @Test
    func compressionNeverMutatesSourceAndNeverReturnsLargerOutput() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanup() }

        let source = try fixture.makeImageHeavyPDF()
        let before = try Data(contentsOf: source)

        do {
            let result = try await fixture.service.compress(
                sourceURL: source,
                filename: "compressed.pdf"
            )

            #expect(result.compressedBytes < result.originalBytes)
            #expect(result.savedFraction > 0)
            let output = try #require(PDFDocument(url: result.url))
            #expect(output.pageCount == 2)
        } catch PDFCompressionService.CompressionError.noMeaningfulSavings {
            #expect(!FileManager.default.fileExists(
                atPath: fixture.root.appending(path: "compressed.pdf").path()
            ))
        }

        #expect(try Data(contentsOf: source) == before)
    }

    @Test
    func refusesToOverwriteSource() async throws {
        let fixture = try Fixture()
        defer { fixture.cleanup() }

        let source = try fixture.makeImageHeavyPDF()

        await #expect(throws: PDFCompressionService.CompressionError.self) {
            _ = try await fixture.service.compress(
                sourceURL: source,
                filename: source.lastPathComponent
            )
        }
    }

    private final class Fixture {
        let root: URL
        let service: PDFCompressionService

        init() throws {
            root = FileManager.default.temporaryDirectory
                .appending(path: "PDFCompressionTests-\(UUID().uuidString)", directoryHint: .isDirectory)
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            service = PDFCompressionService(outputDirectory: root)
        }

        func makeImageHeavyPDF() throws -> URL {
            let document = PDFDocument()

            for pageIndex in 0..<2 {
                let image = UIGraphicsImageRenderer(
                    size: CGSize(width: 1800, height: 2400)
                ).image { context in
                    UIColor.white.setFill()
                    context.cgContext.fill(CGRect(x: 0, y: 0, width: 1800, height: 2400))

                    for index in 0..<120 {
                        let value = CGFloat((index * 37 + pageIndex * 53) % 255) / 255
                        UIColor(
                            red: value,
                            green: 1 - value,
                            blue: CGFloat(index % 17) / 17,
                            alpha: 1
                        ).setFill()
                        let x = CGFloat((index * 97) % 1700)
                        let y = CGFloat((index * 149) % 2300)
                        context.cgContext.fillEllipse(
                            in: CGRect(x: x, y: y, width: 90, height: 90)
                        )
                    }
                }

                document.insert(try #require(PDFPage(image: image)), at: document.pageCount)
            }

            let url = root.appending(path: "source.pdf")
            #expect(document.write(to: url))
            return url
        }

        func cleanup() {
            try? FileManager.default.removeItem(at: root)
        }
    }
}
