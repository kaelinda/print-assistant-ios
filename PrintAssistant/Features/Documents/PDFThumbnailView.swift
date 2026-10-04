import PDFKit
import SwiftUI

struct PDFThumbnailView: View {
    let url: URL

    var body: some View {
        if let page = PDFDocument(url: url)?.page(at: 0) {
            Image(uiImage: page.thumbnail(of: CGSize(width: 640, height: 900), for: .mediaBox))
                .resizable().scaledToFit().padding(DesignTokens.Spacing.md)
        } else {
            ContentUnavailableView("无法预览", systemImage: "doc")
        }
    }
}
