import PDFKit
import SwiftUI

struct PDFPreviewView: View {
    @Environment(AppModel.self) private var appModel
    let documentID: DocumentRecord.ID

    var body: some View {
        Group {
            if let document = appModel.library.document(id: documentID), document.isPasswordProtected {
                ContentUnavailableView {
                    Label("文件已加密", systemImage: "lock.doc")
                } description: {
                    Text("解锁后才能预览、识别或打印。")
                } actions: {
                    Button("解除 PDF 密码") {
                        appModel.push(.pdfUtility(.unlock, document.id))
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else if let document = appModel.library.document(id: documentID) {
                PDFKitView(url: document.localURL)
                    .ignoresSafeArea(edges: .bottom)
                    .navigationTitle("打印预览")
                    .navigationBarTitleDisplayMode(.inline)
                    .safeAreaInset(edge: .bottom) {
                        if let template = appModel.activePrintTemplate {
                            Text("打印模板：\(template.name) · \(template.paper) · \(template.scale) · \(template.copies) 份")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(.regularMaterial)
                        }
                    }
                    .toolbar {
                        ToolbarItemGroup(placement: .topBarTrailing) {
                            ShareLink(item: document.localURL) { Image(systemName: "square.and.arrow.up") }
                                .accessibilityLabel("分享")
                            Button {
                                PrintService.present(
                                    url: document.localURL,
                                    jobName: document.name,
                                    template: appModel.activePrintTemplate
                                )
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
