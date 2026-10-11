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
                        let items = selected.compactMap { id -> BatchJob.Item? in
                            guard let document = appModel.library.document(id: id) else { return nil }
                            return BatchJob.Item(id: id, name: document.name)
                        }
                        guard !items.isEmpty else { return }
                        appModel.push(.batchProcessing(BatchJob(items: items)))
                    }
                }
                .padding(16)
                .background(.regularMaterial)
            }
        }
        .navigationTitle("批量处理")
        .navigationBarTitleDisplayMode(.inline)
        .libraryFileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: true,
            importer: appModel.pdfImportService,
            onStart: {},
            onFailure: { errorMessage = $0 },
            onFiles: { sources in
                do {
                    for source in sources {
                        guard let inspection = PDFFileInspection.inspect(url: source.url) else {
                            appModel.pdfImportService.cleanup([source])
                            continue
                        }
                        let values = try source.url.resourceValues(forKeys: [.fileSizeKey])
                        let record = DocumentRecord(
                            name: source.displayName,
                            pageCount: inspection.pageCount,
                            byteCount: Int64(values.fileSize ?? 0),
                            source: .files,
                            localURL: source.url,
                            isPasswordProtected: inspection.isLocked
                        )
                        try appModel.library.add(record)
                    }
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        )
        .alert("无法添加文件", isPresented: .init(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("好", role: .cancel) {}
        } message: { Text(errorMessage ?? String(localized: "未知错误")) }
    }
}

struct BatchProcessingView: View {
    @Environment(AppModel.self) private var appModel
    @State private var job: BatchJob
    @State private var cancelRequested = false
    @State private var errorMessage: String?
    @State private var attempt = 0

    init(job: BatchJob) {
        _job = State(initialValue: job)
    }

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            if let errorMessage {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundStyle(DesignTokens.Color.warning)
                Text("批量处理失败").font(.title2.bold())
                Text(errorMessage).multilineTextAlignment(.center).foregroundStyle(.secondary)
                PrimaryActionButton(title: "重试", state: .enabled) {
                    self.errorMessage = nil
                    cancelRequested = false
                    attempt += 1
                }
            } else {
                ProgressView(value: job.progress)
                    .padding(.horizontal, 32)
                Text("正在逐个压缩").font(.title2.bold())
                Text("\(job.finishedCount) / \(job.items.count)")
                    .foregroundStyle(.secondary)
                if let current = job.items.first(where: { if case .running = $0.state { return true }; return false }) {
                    Text(current.name)
                        .font(.headline)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
                Button("取消") { cancelRequested = true }
                    .buttonStyle(.bordered)
                    .disabled(cancelRequested)
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
            let finished = try await appModel.runExclusive {
                try await compressEachFile()
            }
            appModel.replaceTop(with: .batchSuccess(finished))
        } catch is CancellationError {
            var partial = job
            partial.cancelRemaining()
            appModel.replaceTop(with: .batchSuccess(partial))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func compressEachFile() async throws -> BatchJob {
        for index in job.items.indices {
            try Task.checkCancellation()
            if cancelRequested {
                job.cancelRemaining()
                return job
            }

            let sourceID = job.items[index].id
            job.markRunning(sourceID)

            guard let document = appModel.library.document(id: sourceID) else {
                job.markFailed(sourceID, message: String(localized: "文件不存在或已被移动。"))
                continue
            }
            if document.isPasswordProtected {
                job.markFailed(sourceID, message: String(localized: "文件已加密，需要先解锁。"))
                continue
            }

            do {
                let filename = "\(String(localized: "批量压缩"))-\(UUID().uuidString).pdf"
                let result = try await PDFCompressionService().compress(
                    sourceURL: document.localURL,
                    filename: filename
                )
                let values = try result.url.resourceValues(forKeys: [.fileSizeKey])
                let record = DocumentRecord(
                    name: "\(document.name)-\(String(localized: "压缩")).pdf",
                    pageCount: PDFDocument(url: result.url)?.pageCount ?? document.pageCount,
                    byteCount: Int64(values.fileSize ?? 0),
                    source: .generated,
                    localURL: result.url
                )
                try appModel.library.add(record)
                job.markSucceeded(sourceID, result: record.id)
            } catch is CancellationError {
                job.cancelRemaining()
                throw CancellationError()
            } catch {
                job.markFailed(sourceID, message: error.localizedDescription)
            }
        }
        return job
    }
}

struct BatchSuccessView: View {
    @Environment(AppModel.self) private var appModel
    let job: BatchJob

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Image(systemName: job.succeededIDs.isEmpty ? "exclamationmark.circle" : "checkmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(job.succeededIDs.isEmpty ? DesignTokens.Color.warning : DesignTokens.Color.success)
                Text(verbatim: job.isCancelled ? String(localized: "批量处理已取消") : String(localized: "批量处理完成"))
                    .font(.title2.bold())
                Text(verbatim: AppCopy.batchSummary(
                    succeeded: job.succeededIDs.count,
                    failed: failedCount,
                    cancelled: cancelledCount
                ))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                ForEach(job.items) { item in
                    switch item.state {
                    case .succeeded(let id):
                        if let document = appModel.library.document(id: id) {
                            Button {
                                appModel.push(.pdfPreview(document.id))
                            } label: {
                                HStack {
                                    Image(systemName: "checkmark.circle")
                                        .foregroundStyle(DesignTokens.Color.success)
                                    Text(document.name).lineLimit(1)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    case .failed(let message):
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name).font(.headline)
                            Text(message)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    case .cancelled:
                        Text("\(item.name) 已取消")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundStyle(.secondary)
                    case .pending, .running:
                        EmptyView()
                    }
                }

                Button("返回文件") {
                    appModel.selectedTab = .files
                    appModel.popToRoot()
                }
            }
            .padding(24)
        }
        .navigationTitle("完成")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var failedCount: Int {
        job.items.filter { if case .failed = $0.state { return true }; return false }.count
    }

    private var cancelledCount: Int {
        job.items.filter { if case .cancelled = $0.state { return true }; return false }.count
    }
}
