import PDFKit
import SwiftUI
import UniformTypeIdentifiers

struct BatchSelectionView: View {
    @Environment(AppModel.self) private var appModel
    @State private var selected = Set<DocumentRecord.ID>()
    @State private var isImporting = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            if appModel.library.documents.isEmpty {
                ContentUnavailableView {
                    Label("选择要批量处理的文件", systemImage: "square.stack.3d.up")
                } description: {
                    Text("可以先扫描、导入或生成文件。")
                } actions: {
                    Button("从文件选择") { isImporting = true }
                }
            } else {
                List(appModel.library.documents, selection: $selected) { document in
                    HStack {
                        Image(systemName: document.source == .photos ? "photo" : "doc.text")
                            .foregroundStyle(DesignTokens.Color.accent)
                        VStack(alignment: .leading) {
                            Text(document.name)
                            Text("\(document.pageCount) 页").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .tag(document.id)
                }
                .environment(\.editMode, .constant(.active))

                VStack(spacing: 10) {
                    Button("从文件添加") { isImporting = true }
                        .buttonStyle(.bordered)
                    PrimaryActionButton(
                        title: "开始批量处理",
                        state: selected.isEmpty ? .disabled : .enabled
                    ) {
                        appModel.push(.batchProcessing(Array(selected)))
                    }
                }
                .padding(16)
                .background(.regularMaterial)
            }
        }
        .navigationTitle("批量处理")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: true
        ) { result in
            Task {
                do {
                    let sources = try await appModel.pdfImportService.stage(urls: try result.get())
                    for source in sources {
                        guard let values = try? source.url.resourceValues(forKeys: [.fileSizeKey]),
                              let pageCount = PDFDocument(url: source.url)?.pageCount else { continue }
                        let record = DocumentRecord(
                            name: source.displayName,
                            pageCount: pageCount,
                            byteCount: Int64(values.fileSize ?? 0),
                            source: .files,
                            localURL: source.url
                        )
                        try appModel.library.add(record)
                    }
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
        .alert("无法添加文件", isPresented: .init(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("好", role: .cancel) {}
        } message: { Text(errorMessage ?? "未知错误") }
    }
}

struct BatchProcessingView: View {
    @Environment(AppModel.self) private var appModel
    let documentIDs: [DocumentRecord.ID]
    @State private var errorMessage: String?
    @State private var attempt = 0

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            if let errorMessage {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 48))
                    .foregroundStyle(DesignTokens.Color.warning)
                Text("批量处理失败").font(.title2.bold())
                Text(errorMessage).multilineTextAlignment(.center).foregroundStyle(.secondary)
                PrimaryActionButton(title: "重试", state: .enabled) {
                    self.errorMessage = nil
                    attempt += 1
                }
            } else {
                ProgressView().controlSize(.large)
                Text("正在批量处理").font(.title2.bold())
                Text("已选择 \(documentIDs.count) 个文件").foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(24)
        .navigationTitle("批量处理")
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(errorMessage == nil)
        .task(id: attempt) {
            guard errorMessage == nil else { return }
            await process()
        }
    }

    @MainActor
    private func process() async {
        do {
            let records = documentIDs.compactMap { appModel.library.document(id: $0) }
            guard let first = records.first else { throw PDFOperationService.OperationError.insufficientInputs }
            let urls = records.map(\.localURL)
            let outputURL: URL
            if urls.count >= 2 {
                outputURL = try await appModel.pdfOperationService.merge(
                    urls: urls,
                    filename: "批量处理-\(Int(Date.now.timeIntervalSince1970)).pdf"
                )
            } else {
                outputURL = first.localURL
            }
            if urls.count == 1 {
                appModel.replaceTop(with: .batchSuccess(documentIDs))
                return
            }
            let values = try outputURL.resourceValues(forKeys: [.fileSizeKey])
            let record = DocumentRecord(
                name: outputURL.lastPathComponent,
                pageCount: PDFDocument(url: outputURL)?.pageCount ?? 1,
                byteCount: Int64(values.fileSize ?? 0),
                source: .generated,
                localURL: outputURL
            )
            try appModel.library.add(record)
            appModel.replaceTop(with: .batchSuccess([record.id]))
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct BatchSuccessView: View {
    @Environment(AppModel.self) private var appModel
    let documentIDs: [DocumentRecord.ID]

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 62))
                .foregroundStyle(DesignTokens.Color.success)
            Text("批量处理完成").font(.title2.bold())
            Text("已生成 \(documentIDs.count) 个结果文件")
                .foregroundStyle(.secondary)
            ForEach(documentIDs, id: \.self) { id in
                if let document = appModel.library.document(id: id) {
                    Button {
                        appModel.push(.pdfPreview(document.id))
                    } label: {
                        HStack {
                            Text(document.name)
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
            Button("返回文件") {
                appModel.selectedTab = .files
                appModel.popToRoot()
            }
            Spacer()
        }
        .padding(24)
        .navigationTitle("完成")
        .navigationBarTitleDisplayMode(.inline)
    }
}
