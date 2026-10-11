import PDFKit
import SwiftUI
import UniformTypeIdentifiers

enum PDFUtilityMode: Hashable, Sendable {
    case compress
    case protect
    case unlock

    var title: String {
        switch self {
        case .compress: "压缩 PDF"
        case .protect: "加密 PDF"
        case .unlock: "解除 PDF 密码"
        }
    }

    var actionTitle: String {
        switch self {
        case .compress: "压缩并保存新文件"
        case .protect: "加密并保存新文件"
        case .unlock: "解密并保存新文件"
        }
    }

    var successTitle: String {
        switch self {
        case .compress: "PDF 压缩完成"
        case .protect: "PDF 加密完成"
        case .unlock: "PDF 解密完成"
        }
    }

    var outputPrefix: String {
        switch self {
        case .compress: "压缩文件"
        case .protect: "加密文件"
        case .unlock: "解密文件"
        }
    }
}

struct PDFUtilityView: View {
    @Environment(AppModel.self) private var appModel
    let mode: PDFUtilityMode

    @State private var selected: PDFSourceItem?
    @State private var isImporting = false
    @State private var isStaging = false
    @State private var isWorking = false
    @State private var password = ""
    @State private var ownerPassword = ""
    @State private var errorMessage: String?
    @State private var completedID: DocumentRecord.ID?
    @State private var savedFraction: Double?

    private var pdfDocuments: [DocumentRecord] {
        appModel.library.documents.filter {
            $0.localURL.pathExtension.lowercased() == "pdf"
        }
    }

    private var canProcess: Bool {
        guard selected != nil, !isWorking, !isStaging else { return false }
        switch mode {
        case .compress: return true
        case .protect: return !password.isEmpty && !ownerPassword.isEmpty
        case .unlock: return !password.isEmpty
        }
    }

    var body: some View {
        List {
            if let record = completedID.flatMap(appModel.library.document(id:)) {
                Section {
                    Label(mode.successTitle, systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .foregroundStyle(DesignTokens.Color.success)
                    Text(record.name)
                        .lineLimit(2)
                    if let savedFraction {
                        Text("文件体积减少 \(Int((savedFraction * 100).rounded()))%")
                            .foregroundStyle(.secondary)
                    }
                    Text("新文件已保存到本机，原文件保持不变。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    if mode != .protect {
                        Button("预览 / 打印") {
                            appModel.push(.pdfPreview(record.id))
                        }
                    }
                    ShareLink(item: record.localURL) {
                        Label("分享 PDF", systemImage: "square.and.arrow.up")
                    }
                    Button("返回文件") {
                        appModel.selectedTab = .files
                        appModel.popToRoot()
                    }
                } header: {
                    Text("处理结果")
                }
            } else {
                Section("已选择") {
                    if let selected {
                        Label(selected.displayName, systemImage: "doc")
                            .lineLimit(2)
                    } else {
                        Text("请选择需要处理的 PDF")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("本机文件") {
                    if pdfDocuments.isEmpty {
                        Text("文件库中还没有 PDF")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(pdfDocuments) { document in
                            Button {
                                choose(.init(
                                    url: document.localURL,
                                    displayName: document.name
                                ))
                            } label: {
                                HStack {
                                    Image(systemName: selected?.url == document.localURL
                                        ? "checkmark.circle.fill" : "doc")
                                        .foregroundStyle(DesignTokens.Color.accent)
                                    Text(document.name)
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                    Spacer()
                                    Text("\(document.pageCount) 页")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
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
                    .disabled(isStaging || isWorking)
                    if isStaging {
                        ProgressView("正在导入文件…")
                    }
                }

                if mode != .compress {
                    Section("密码") {
                        SecureField(
                            mode == .unlock ? "当前 PDF 密码" : "打开 PDF 的密码",
                            text: $password
                        )
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        if mode == .protect {
                            SecureField("所有者密码", text: $ownerPassword)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }
                        Text(mode == .protect
                             ? "请妥善保存密码。忘记密码可能无法恢复文件。"
                             : "仅在输入正确密码后才会生成未加密的新文件。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Section {
                        Text("只在压缩后文件确实更小时保存结果，不会修改源文件。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if completedID == nil {
                Button {
                    Task { await process() }
                } label: {
                    HStack {
                        if isWorking {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(isWorking ? "正在处理…" : mode.actionTitle)
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canProcess)
                .accessibilityIdentifier("pdf-utility-run")
                .padding(DesignTokens.Spacing.lg)
                .background(.regularMaterial)
            }
        }
        .navigationTitle(mode.title)
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            stage(result)
        }
        .onDisappear {
            if let selected {
                appModel.pdfImportService.cleanup([selected])
            }
        }
        .alert("PDF 处理失败", isPresented: .init(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("好", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "未知错误")
        }
    }

    @MainActor
    private func choose(_ source: PDFSourceItem) {
        if let previous = selected {
            appModel.pdfImportService.cleanup([previous])
        }
        selected = source
        completedID = nil
        savedFraction = nil
    }

    private func stage(_ result: Result<[URL], Error>) {
        Task { @MainActor in
            isStaging = true
            defer { isStaging = false }
            do {
                guard let url = try result.get().first else { return }
                let items = try await appModel.pdfImportService.stage(urls: [url])
                guard let staged = items.first else { return }
                choose(staged)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    @MainActor
    private func process() async {
        guard canProcess, let source = selected else { return }
        isWorking = true
        defer { isWorking = false }

        let filename = "\(mode.outputPrefix)-\(UUID().uuidString).pdf"
        do {
            let output: URL
            var compression: PDFCompressionService.Result?
            switch mode {
            case .compress:
                let result = try await PDFCompressionService().compress(
                    sourceURL: source.url,
                    filename: filename
                )
                output = result.url
                compression = result
            case .protect:
                output = try await PDFProtectionService().protect(
                    .init(
                        sourceURL: source.url,
                        userPassword: password,
                        ownerPassword: ownerPassword
                    ),
                    filename: filename
                )
            case .unlock:
                output = try await PDFProtectionService().removeProtection(
                    sourceURL: source.url,
                    password: password,
                    filename: filename
                )
            }

            do {
                let pageCount: Int
                if mode == .protect {
                    guard let document = PDFDocument(url: source.url), document.pageCount > 0 else {
                        throw PDFProtectionService.ProtectionError.unreadablePDF
                    }
                    pageCount = document.pageCount
                } else {
                    guard let document = PDFDocument(url: output), document.pageCount > 0 else {
                        throw PDFProtectionService.ProtectionError.unreadablePDF
                    }
                    pageCount = document.pageCount
                }
                let values = try output.resourceValues(forKeys: [.fileSizeKey])
                let record = DocumentRecord(
                    name: filename,
                    pageCount: pageCount,
                    byteCount: Int64(values.fileSize ?? 0),
                    source: .generated,
                    localURL: output,
                    isPasswordProtected: mode == .protect
                )
                try appModel.library.add(record)
                savedFraction = compression?.savedFraction
                completedID = record.id
                appModel.pdfImportService.cleanup([source])
                selected = nil
                password = ""
                ownerPassword = ""
            } catch {
                try? FileManager.default.removeItem(at: output)
                throw error
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
