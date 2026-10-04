import PDFKit
import SwiftUI
import UniformTypeIdentifiers

struct PDFPageSourceView: View {
    @Environment(AppModel.self) private var appModel
    @State private var isImporting = false
    @State private var isStaging = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section("本机文件") {
                if appModel.library.documents.isEmpty {
                    Text("文件库中还没有 PDF")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(appModel.library.documents) { document in
                        Button {
                            open(.init(url: document.localURL, displayName: document.name))
                        } label: {
                            HStack {
                                Image(systemName: "doc")
                                    .foregroundStyle(DesignTokens.Color.accent)
                                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                                    Text(document.name)
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                    Text("\(document.pageCount) 页")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(minHeight: DesignTokens.minimumHitTarget)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Section {
                Button {
                    isImporting = true
                } label: {
                    Label("从文件选择 PDF", systemImage: "folder")
                }
                .disabled(isStaging)

                if isStaging {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        ProgressView()
                        Text("正在导入…").foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("页面管理")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            stage(result)
        }
        .alert("无法读取 PDF", isPresented: .init(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("好", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "未知错误")
        }
    }

    private func open(_ source: PDFSourceItem) {
        guard let document = PDFDocument(url: source.url), document.pageCount > 0 else {
            if source.isTemporary { appModel.pdfImportService.cleanup([source]) }
            errorMessage = PDFOperationService.OperationError.unreadablePDF.localizedDescription
            return
        }
        guard !document.isLocked else {
            if source.isTemporary { appModel.pdfImportService.cleanup([source]) }
            errorMessage = PDFOperationService.OperationError.lockedPDF.localizedDescription
            return
        }

        appModel.push(.pdfPageEditor(.init(
            source: source,
            originalPageCount: document.pageCount,
            pageIndexes: Array(0..<document.pageCount)
        )))
    }

    private func stage(_ result: Result<[URL], Error>) {
        Task {
            do {
                isStaging = true
                let imported = try await appModel.pdfImportService.stage(urls: try result.get())
                isStaging = false
                guard let source = imported.first else { return }
                open(source)
            } catch {
                isStaging = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
