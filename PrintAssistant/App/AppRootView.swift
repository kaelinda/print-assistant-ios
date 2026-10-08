import SwiftUI

struct AppRootView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        @Bindable var appModel = appModel

        NavigationStack(path: $appModel.path) {
            TabView(selection: $appModel.selectedTab) {
                RecentView()
                    .tag(AppModel.Tab.recent)
                    .tabItem { Label("最近", systemImage: "clock") }

                FilesView()
                    .tag(AppModel.Tab.files)
                    .tabItem { Label("文件", systemImage: "folder") }

                ToolsView()
                    .tag(AppModel.Tab.tools)
                    .tabItem { Label("工具", systemImage: "square.grid.2x2") }

                SearchView()
                    .tag(AppModel.Tab.search)
                    .tabItem { Label("搜索", systemImage: "magnifyingglass") }
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
}

