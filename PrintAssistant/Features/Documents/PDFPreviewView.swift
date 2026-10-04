import PDFKit
import SwiftUI

struct PDFPreviewView: View {
    @Environment(AppModel.self) private var appModel
    let documentID: DocumentRecord.ID

    var body: some View {
        Group {
            if let document = appModel.library.document(id: documentID) {
                PDFKitView(url: document.localURL)
                    .ignoresSafeArea(edges: .bottom)
                    .navigationTitle("打印预览")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItemGroup(placement: .topBarTrailing) {
                            ShareLink(item: document.localURL) { Image(systemName: "square.and.arrow.up") }
                                .accessibilityLabel("分享")
                            Button {
                                PrintService.present(url: document.localURL, jobName: document.name)
                            } label: {
                                Image(systemName: "printer")
                            }
                            .accessibilityLabel("打印")
                        }
                    }
            } else {
                ContentUnavailableView("文件不存在", systemImage: "doc.badge.exclamationmark")
            }
        }
    }
}

private struct PDFKitView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.document = PDFDocument(url: url)
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document?.documentURL != url {
            uiView.document = PDFDocument(url: url)
        }
    }
}
