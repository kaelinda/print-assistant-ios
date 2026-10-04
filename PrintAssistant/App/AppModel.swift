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
    }

    var selectedTab: Tab = .recent
    var path: [Route] = []
    var isWorking = false
    var transientMessage: String?

    let library: DocumentLibrary
    let pdfService: PDFDocumentService

    init(
        library: DocumentLibrary = .init(),
        pdfService: PDFDocumentService = .init()
    ) {
        self.library = library
        self.pdfService = pdfService
    }

    func push(_ route: Route) {
        path.append(route)
    }

    func popToRoot() {
        path.removeAll()
    }
}
