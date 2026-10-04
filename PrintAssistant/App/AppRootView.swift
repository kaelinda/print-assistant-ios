import SwiftUI

struct AppRootView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        @Bindable var appModel = appModel
        NavigationStack(path: $appModel.path) {
            TabView(selection: $appModel.selectedTab) {
                RecentView().tag(AppModel.Tab.recent).tabItem { Label("最近", systemImage: "clock") }
                FilesView().tag(AppModel.Tab.files).tabItem { Label("文件", systemImage: "folder") }
                ToolsView().tag(AppModel.Tab.tools).tabItem { Label("工具", systemImage: "square.grid.2x2") }
                SearchView().tag(AppModel.Tab.search).tabItem { Label("搜索", systemImage: "magnifyingglass") }
            }
            .navigationDestination(for: AppModel.Route.self) { route in
                switch route {
                case .scanner: ScannerView()
                case .scanReview(let draft): ScanReviewView(draft: draft)
                case .document(let id): FileDetailView(documentID: id)
                case .pdfPreview(let id): PDFPreviewView(documentID: id)
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

private struct FilesView: View {
    var body: some View {
        ContentUnavailableView("文件", systemImage: "folder", description: Text("扫描件和生成的 PDF 会保存在这里。"))
    }
}

private struct ToolsView: View {
    var body: some View {
        ContentUnavailableView("工具", systemImage: "square.grid.2x2", description: Text("OCR、PDF 工具和证件排版将在后续实现批次接入。"))
    }
}

private struct SearchView: View {
    var body: some View {
        ContentUnavailableView("搜索", systemImage: "magnifyingglass", description: Text("文件名和 OCR 全文搜索将在索引层完成后接入。"))
    }
}
