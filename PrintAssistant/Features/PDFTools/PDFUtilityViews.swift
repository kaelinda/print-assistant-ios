import PDFKit
import SwiftUI
import UniformTypeIdentifiers

struct PDFCompressionSourceView: View {
    @Environment(AppModel.self) private var appModel
    @State private var isImporting = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section("文件库") {
                if appModel.library.documents.isEmpty {
                    Text("文件库中还没有可压缩的 PDF").foregroundStyle(.secondary)
                } else {
                    ForEach(appModel.library.documents) { document in
                        Button {
                            appModel.push(.pdfCompressionProcessing(.init(url: document.localURL, displayName: document.name)))
                        } label: {
                            documentRow(document.name, detail: "\(document.pageCount) 页")
                        }
                    }
                }
            }
            Section {
                Button("从文件选择 PDF", systemImage: "folder") {
                    isImporting = true
                }
            }
        }
        .navigationTitle("压缩 PDF")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.pdf]) { result in
            Task {
                do {
                    let sources = try await appModel.pdfImportService.stage(urls: [try result.get()])
                    guard let source = sources.first else { return }
                    appModel.push(.pdfCompressionProcessing(source))
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
        .alert("无法读取 PDF", isPresented: .init(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("好", role: .cancel) {}
        } message: { Text(errorMessage ?? "未知错误") }
    }

    private func documentRow(_ title: String, detail: String) -> some View {
        HStack {
            Image(systemName: "doc.zipper").foregroundStyle(DesignTokens.Color.accent)
            VStack(alignment: .leading) {
                Text(title)
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
        }
        .frame(minHeight: DesignTokens.minimumHitTarget)
    }
}

struct PDFCompressionProcessingView: View {
    @Environment(AppModel.self) private var appModel
    let source: PDFSourceItem
    @State private var errorMessage: String?
    @State private var attempt = 0

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            if let errorMessage {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 48))
                    .foregroundStyle(DesignTokens.Color.warning)
                Text("压缩失败").font(.title2.bold())
                Text(errorMessage).multilineTextAlignment(.center).foregroundStyle(.secondary)
                PrimaryActionButton(title: "重试", state: .enabled) {
                    self.errorMessage = nil
                    attempt += 1
                }
            } else {
                ProgressView().controlSize(.large)
                Text("正在压缩 PDF").font(.title2.bold())
                Text(source.displayName).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(24)
        .navigationTitle("压缩 PDF")
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(errorMessage == nil)
        .task(id: attempt) {
            guard errorMessage == nil else { return }
            await compress()
        }
    }

    @MainActor
    private func compress() async {
        do {
            let filename = "\(source.displayName.replacingOccurrences(of: ".pdf", with: ""))-压缩.pdf"
            let result = try await PDFCompressionService().compress(sourceURL: source.url, filename: filename)
            let values = try result.url.resourceValues(forKeys: [.fileSizeKey])
            let record = DocumentRecord(
                name: filename,
                pageCount: PDFDocument(url: result.url)?.pageCount ?? 1,
                byteCount: Int64(values.fileSize ?? 0),
                source: .generated,
                localURL: result.url
            )
            try appModel.library.add(record)
            appModel.replaceTop(with: .pdfCompressionSuccess(record.id))
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct PDFCompressionSuccessView: View {
    @Environment(AppModel.self) private var appModel
    let documentID: DocumentRecord.ID

    var body: some View {
        if let document = appModel.library.document(id: documentID) {
            VStack(spacing: 18) {
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 62))
                    .foregroundStyle(DesignTokens.Color.success)
                Text("PDF 已压缩").font(.title2.bold())
                Text(document.name).font(.headline)
                Text("文件已保存到本机").foregroundStyle(.secondary)
                PrimaryActionButton(title: "预览 / 分享", state: .enabled) {
                    appModel.push(.pdfPreview(document.id))
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
        } else {
            ContentUnavailableView("文件不存在", systemImage: "doc.badge.exclamationmark")
        }
    }
}

struct PDFProtectionSourceView: View {
    @Environment(AppModel.self) private var appModel
    @State private var isImporting = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section("选择 PDF") {
                ForEach(appModel.library.documents) { document in
                    Button {
                        appModel.push(.pdfProtection(.init(url: document.localURL, displayName: document.name)))
                    } label: {
                        HStack {
                            Image(systemName: "lock.doc").foregroundStyle(DesignTokens.Color.accent)
                            Text(document.name)
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                        }
                        .frame(minHeight: DesignTokens.minimumHitTarget)
                    }
                }
                Button("从文件选择 PDF", systemImage: "folder") { isImporting = true }
            }
        }
        .navigationTitle("保护 PDF")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.pdf]) { result in
            Task {
                do {
                    let sources = try await appModel.pdfImportService.stage(urls: [try result.get()])
                    guard let source = sources.first else { return }
                    appModel.push(.pdfProtection(source))
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
        .alert("无法读取 PDF", isPresented: .init(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("好", role: .cancel) {}
        } message: { Text(errorMessage ?? "未知错误") }
    }
}

struct PDFProtectionView: View {
    @Environment(AppModel.self) private var appModel
    let source: PDFSourceItem
    @State private var password = ""
    @State private var confirmation = ""
    @State private var errorMessage: String?
    @State private var isWorking = false

    var body: some View {
        Form {
            Section("密码") {
                SecureField("输入密码", text: $password)
                SecureField("再次输入密码", text: $confirmation)
                if !confirmation.isEmpty && password != confirmation {
                    Text("两次密码不一致").foregroundStyle(.red)
                }
            }
            Section {
                Text("会生成一个新的受保护 PDF，源文件保持不变。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                PrimaryActionButton(
                    title: "保护 PDF",
                    state: isWorking ? .processing : (password.isEmpty || password != confirmation ? .disabled : .enabled)
                ) {
                    protect()
                }
            }
            .listRowInsets(.init())
            .listRowBackground(Color.clear)
        }
        .navigationTitle("设置密码")
        .navigationBarTitleDisplayMode(.inline)
        .alert("无法保护 PDF", isPresented: .init(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("好", role: .cancel) {}
        } message: { Text(errorMessage ?? "未知错误") }
    }

    private func protect() {
        guard !isWorking else { return }
        isWorking = true
        Task {
            do {
                let name = "\(source.displayName.replacingOccurrences(of: ".pdf", with: ""))-已保护.pdf"
                let url = try await PDFProtectionService().protect(
                    .init(sourceURL: source.url, userPassword: password, ownerPassword: password),
                    filename: name
                )
                let values = try url.resourceValues(forKeys: [.fileSizeKey])
                let record = DocumentRecord(
                    name: name,
                    pageCount: PDFDocument(url: url)?.pageCount ?? 1,
                    byteCount: Int64(values.fileSize ?? 0),
                    source: .generated,
                    localURL: url,
                    isPasswordProtected: true
                )
                try await MainActor.run {
                    try appModel.library.add(record)
                    appModel.replaceTop(with: .pdfProtectionSuccess(record.id))
                }
            } catch {
                await MainActor.run {
                    isWorking = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct PDFProtectionSuccessView: View {
    @Environment(AppModel.self) private var appModel
    let documentID: DocumentRecord.ID

    var body: some View {
        if let document = appModel.library.document(id: documentID) {
            VStack(spacing: 18) {
                Spacer()
                Image(systemName: "lock.circle.fill")
                    .font(.system(size: 62))
                    .foregroundStyle(DesignTokens.Color.success)
                Text("PDF 已保护").font(.title2.bold())
                Text(document.name).font(.headline)
                PrimaryActionButton(title: "预览 / 分享", state: .enabled) {
                    appModel.push(.pdfPreview(document.id))
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
        } else {
            ContentUnavailableView("文件不存在", systemImage: "doc.badge.exclamationmark")
        }
    }
}
