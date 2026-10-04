import PDFKit
import UIKit

struct PDFDocumentService {
    enum PDFError: Error {
        case unableToCreatePage
        case unableToWrite
    }

    func makePDF(from images: [UIImage], filename: String) throws -> URL {
        let document = PDFDocument()

        for (index, image) in images.enumerated() {
            guard let page = PDFPage(image: image) else {
                throw PDFError.unableToCreatePage
            }
            document.insert(page, at: index)
        }

        let directory = try documentsDirectory()
        let url = directory.appending(path: filename, directoryHint: .notDirectory)

        guard document.write(to: url) else {
            throw PDFError.unableToWrite
        }
        return url
    }

    private func documentsDirectory() throws -> URL {
        let base = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = base.appending(path: "Documents", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
