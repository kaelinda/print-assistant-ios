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

        case photoPDFSelection
        case photoPDFLayout(PhotoPDFDraft)
        case photoPDFGenerating(PhotoPDFDraft)
        case photoPDFSuccess(DocumentRecord.ID)

        case idCopyCapture(IDCopyDraft, IDCopyDraft.Side)
        case idCopyConfirm(IDCopyDraft, IDCopyDraft.Side, Data)
        case idCopyLayout(IDCopyDraft)
        case idCopyGenerating(IDCopyDraft)
        case idCopySuccess(DocumentRecord.ID)

        case pdfMergeSelection
        case pdfMergeProcessing(PDFMergeDraft)
        case pdfMergeSuccess(DocumentRecord.ID)

        case pdfSplitSource
        case pdfSplitEditor(PDFSplitDraft)
        case pdfSplitProcessing(PDFSplitDraft)
        case pdfSplitSuccess([DocumentRecord.ID])

        case pdfPageSource
        case pdfPageEditor(PDFPageManagementDraft)
        case pdfPageProcessing(PDFPageManagementDraft)
        case pdfPageSuccess(DocumentRecord.ID)

        case templateCenter
        case templateEditor(PrintTemplate)
        case templateApply(PrintTemplate)
        case batchSelection
        case batchProcessing(BatchJob)
        case batchSuccess(BatchJob)
        case pdfCompressionSource
        case pdfCompressionProcessing(PDFSourceItem)
        case pdfCompressionSuccess(DocumentRecord.ID)
        case pdfProtectionSource
        case pdfProtection(PDFSourceItem)
        case pdfProtectionSuccess(DocumentRecord.ID)
        case pdfUtility(PDFUtilityMode, DocumentRecord.ID?)
        case photoIDSource
        case photoIDCrop(PhotoIDDraft)
        case photoIDGenerating(PhotoIDDraft)
        case photoIDSuccess(DocumentRecord.ID, sheetCount: Int)
        case imageExport(DocumentRecord.ID)
        case settings
        case privacy
        case privacyPolicy
        case feedback
    }

    enum WorkError: LocalizedError, Equatable {
        case busy

        var errorDescription: String? {
            switch self {
            case .busy: String(localized: "已有处理任务正在进行，请稍候。")
            }
        }
    }

    var selectedTab: Tab = .recent
    var path: [Route] = []
    var isWorking = false
    var transientMessage: String?
    var activePrintTemplate: PrintTemplate?

    /// Runs one merge, compress, or OCR job at a time.
    func runExclusive<T>(_ operation: () async throws -> T) async throws -> T {
        guard !isWorking else { throw WorkError.busy }
        isWorking = true
        defer { isWorking = false }
        return try await operation()
    }

    let library: DocumentLibrary
    let pdfService: PDFDocumentService
    let ocrService: OCRRecognitionService
    let pdfOperationService: PDFOperationService
    let pdfImportService: PDFImportService

    init(
        library: DocumentLibrary = .init(),
        pdfService: PDFDocumentService = .init(),
        ocrService: OCRRecognitionService = .init(),
        pdfOperationService: PDFOperationService = .init(),
        pdfImportService: PDFImportService = .init()
    ) {
        self.library = library
        self.pdfService = pdfService
        self.ocrService = ocrService
        self.pdfOperationService = pdfOperationService
        self.pdfImportService = pdfImportService
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
