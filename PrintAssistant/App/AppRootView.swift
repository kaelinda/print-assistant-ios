import SwiftUI

struct AppRootView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        @Bindable var appModel = appModel

        NavigationStack(path: $appModel.path) {
            rootContent
                .background(DesignTokens.Color.canvas.ignoresSafeArea())
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    if appModel.path.isEmpty {
                        GlassTabBar()
                            .padding(.bottom, 4)
                            .background(DesignTokens.Color.canvas)
                    }
                }
            .navigationDestination(for: AppModel.Route.self) { route in
                switch route {
                case .scanner:
                    ScannerView()
                case .scanReview(let draft):
                    ScanReviewView(draft: draft)
                case .document(let id):
                    FileDetailView(documentID: id)
                case .pdfPreview(let id):
                    PDFPreviewView(documentID: id)
                case .ocrSource:
                    OCRSourceView()
                case .ocrCamera:
                    OCRCameraView()
                case .ocrProcessing(let input):
                    OCRProcessingView(input: input)
                case .ocrResult(let result):
                    OCRResultView(result: result)
                case .photoPDFSelection:
                    PhotoPDFSelectionView()
                case .photoPDFLayout(let draft):
                    PhotoPDFLayoutView(draft: draft)
                case .photoPDFGenerating(let draft):
                    PhotoPDFGeneratingView(draft: draft)
                case .photoPDFSuccess(let id):
                    PhotoPDFSuccessView(documentID: id)
                case .idCopyCapture(let draft, let side):
                    IDCopyCaptureView(draft: draft, side: side)
                case .idCopyConfirm(let draft, let side, let data):
                    IDCopyConfirmView(draft: draft, side: side, capturedData: data)
                case .idCopyLayout(let draft):
                    IDCopyLayoutView(draft: draft)
                case .idCopyGenerating(let draft):
                    IDCopyGeneratingView(draft: draft)
                case .idCopySuccess(let id):
                    IDCopySuccessView(documentID: id)
                case .pdfMergeSelection:
                    PDFMergeSelectionView()
                case .pdfMergeProcessing(let draft):
                    PDFMergeProcessingView(draft: draft)
                case .pdfMergeSuccess(let id):
                    PDFMergeSuccessView(documentID: id)
                case .pdfSplitSource:
                    PDFSplitSourceView()
                case .pdfSplitEditor(let draft):
                    PDFSplitEditorView(draft: draft)
                case .pdfSplitProcessing(let draft):
                    PDFSplitProcessingView(draft: draft)
                case .pdfSplitSuccess(let ids):
                    PDFSplitSuccessView(documentIDs: ids)
                case .pdfPageSource:
                    PDFPageSourceView()
                case .pdfPageEditor(let draft):
                    PDFPageEditorView(draft: draft)
                case .pdfPageProcessing(let draft):
                    PDFPageProcessingView(draft: draft)
                case .pdfPageSuccess(let id):
                    PDFPageSuccessView(documentID: id)
                case .templateCenter:
                    TemplateCenterView()
                case .templateEditor(let template):
                    TemplateEditorView(template: template)
                case .templateApply(let template):
                    TemplateApplyView(template: template)
                case .batchSelection:
                    BatchSelectionView()
                case .batchProcessing(let ids):
                    BatchProcessingView(documentIDs: ids)
                case .batchSuccess(let ids):
                    BatchSuccessView(documentIDs: ids)
                case .pdfCompressionSource:
                    PDFCompressionSourceView()
                case .pdfCompressionProcessing(let source):
                    PDFCompressionProcessingView(source: source)
                case .pdfCompressionSuccess(let id):
                    PDFCompressionSuccessView(documentID: id)
                case .pdfProtectionSource:
                    PDFProtectionSourceView()
                case .pdfProtection(let source):
                    PDFProtectionView(source: source)
                case .pdfProtectionSuccess(let id):
                    PDFProtectionSuccessView(documentID: id)
                case .photoIDSource:
                    PhotoIDSourceView()
                case .photoIDCrop(let draft):
                    PhotoIDCropView(draft: draft)
                case .photoIDGenerating(let draft):
                    PhotoIDGeneratingView(draft: draft)
                case .photoIDSuccess(let id):
                    PhotoIDSuccessView(documentID: id)
                case .imageExport(let id):
                    ImageExportView(documentID: id)
                case .settings:
                    SettingsView()
                case .privacy:
                    PrivacyView()
                case .privacyPolicy:
                    PrivacyPolicyView()
                case .feedback:
                    FeedbackView()
                }
            }
        }
        .overlay(alignment: .bottom) {
            if let message = appModel.transientMessage {
                Text(message)
                    .font(.footnote.weight(.medium))
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .padding(.vertical, DesignTokens.Spacing.sm)
                    .background(.regularMaterial, in: Capsule())
                    .padding(.bottom, 72)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    @ViewBuilder
    private var rootContent: some View {
        switch appModel.selectedTab {
        case .recent:
            RecentView()
        case .files:
            FilesView()
        case .tools:
            ToolsView()
        case .search:
            SearchView()
        }
    }
}
