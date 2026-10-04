import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
    enum Tab: Hashable {
        case recent
        case files
        case tools
        case search
    }

    enum Route: Hashable {
        case scanner
        case scanReview(ScanDraft)
        case document(DocumentRecord.ID)
        case pdfPreview(DocumentRecord.ID)

        case ocrSource
        case ocrCamera
        case ocrProcessing(OCRInput)
        case ocrResult(OCRResult)
    }

    var selectedTab: Tab = .recent
    var path: [Route] = []
    var isWorking = false
    var transientMessage: String?

    let library: DocumentLibrary
    let pdfService: PDFDocumentService
    let ocrService: OCRRecognitionService

    init(
        library: DocumentLibrary = .init(),
        pdfService: PDFDocumentService = .init(),
        ocrService: OCRRecognitionService = .init()
    ) {
        self.library = library
        self.pdfService = pdfService
        self.ocrService = ocrService
    }

    func push(_ route: Route) {
        path.append(route)
    }

    func replaceTop(with route: Route) {
        if !path.isEmpty {
            path.removeLast()
        }
        path.append(route)
    }

    func popToRoot() {
        path.removeAll()
    }
}
