import PDFKit
import SwiftUI
import UniformTypeIdentifiers

struct TemplateCenterView: View {
    @Environment(AppModel.self) private var appModel
    @State private var templates = TemplateStore.load()
    @State private var category: PrintTemplate.Category = .all

    private var visibleTemplates: [PrintTemplate] {
        category == .all ? templates : templates.filter { $0.category == category }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("打印模板")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(DesignTokens.Color.primaryText)
                Text("把重复使用的打印参数保存下来，下次一键套用")
                    .font(.subheadline)
                    .foregroundStyle(DesignTokens.Color.secondaryText)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(PrintTemplate.Category.allCases, id: \.self) { item in
                            GlassChip(title: item.displayName, isSelected: category == item) {
                                category = item
                            }
                        }
                    }
                }

                ForEach(visibleTemplates) { template in
                    Button {
                        appModel.push(.templateApply(template))
                    } label: {
                        HStack(spacing: 14) {
                            Text(template.category == .id ? "ID" : template.category == .photo ? "1IN" : "DOC")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(DesignTokens.Color.accent)
                                .frame(width: 46, height: 46)
                                .background(DesignTokens.Color.stateSurface, in: RoundedRectangle(cornerRadius: 13))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(template.name)
                                    .font(.system(size: 15, weight: .semibold))
                                Text(template.subtitle)
                                    .font(.system(size: 12))
                                    .foregroundStyle(DesignTokens.Color.secondaryText)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(DesignTokens.Color.tertiaryText)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, minHeight: 86)
                    }
                    .buttonStyle(.plain)
                    .background(.white.opacity(0.84), in: RoundedRectangle(cornerRadius: 18))
                    .overlay { RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.9), lineWidth: 1) }
                }

                Button {
                    appModel.push(.templateEditor(.init(
                        name: "新建模板",
                        subtitle: "自定义纸张、比例与边距",
                        category: .document
                    )))
                } label: {
                    Label("保存当前设置为模板", systemImage: "plus")
                        .frame(maxWidth: .infinity, minHeight: 52)
                }
                .buttonStyle(.bordered)
            }
            .padding(24)
        }
        .background(DesignTokens.Color.canvas)
        .navigationTitle("模板中心")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TemplateEditorView: View {
    @Environment(AppModel.self) private var appModel
    @State private var template: PrintTemplate

    init(template: PrintTemplate) {
        _template = State(initialValue: template)
    }

    var body: some View {
        Form {
            Section("模板信息") {
                TextField("名称", text: $template.name)
                TextField("说明", text: $template.subtitle)
                Picker("分类", selection: $template.category) {
                    ForEach(PrintTemplate.Category.allCases.filter { $0 != .all }, id: \.self) {
                        Text($0.displayName).tag($0)
                    }
                }
            }
            Section("打印参数") {
                TextField("纸张", text: $template.paper)
                TextField("缩放", text: $template.scale)
                Stepper("边距 \(template.marginMillimeters) mm", value: $template.marginMillimeters, in: 0...50)
                Stepper("份数 \(template.copies)", value: $template.copies, in: 1...99)
            }
            Section {
                PrimaryActionButton(title: "保存模板", state: template.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .disabled : .enabled) {
                    TemplateStore.upsert(template)
                    appModel.popToRoot()
                    appModel.transientMessage = "模板已保存"
                }
            }
            .listRowInsets(.init())
            .listRowBackground(Color.clear)
        }
        .navigationTitle("模板编辑")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TemplateApplyView: View {
    @Environment(AppModel.self) private var appModel
    let template: PrintTemplate
    @State private var isImporting = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(spacing: 12) {
                    Image(systemName: "checklist")
                        .font(.system(size: 50))
                        .foregroundStyle(DesignTokens.Color.accent)
                    Text(template.name)
                        .font(.title2.bold())
                    Text("\(template.paper) · \(template.scale) · \(template.marginMillimeters) mm 边距 · \(template.copies) 份")
                        .foregroundStyle(DesignTokens.Color.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)

                Text("选择文件")
                    .font(.headline)
                if appModel.library.documents.isEmpty {
                    ContentUnavailableView(
                        "文件库为空",
                        systemImage: "doc",
                        description: Text("可以从系统文件选择器导入 PDF。")
                    )
                    .frame(maxWidth: .infinity)
                } else {
                    VStack(spacing: 0) {
                        ForEach(appModel.library.documents) { document in
                            Button {
                                apply(to: document)
                            } label: {
                                HStack {
                                    Image(systemName: "doc.text")
                                        .foregroundStyle(DesignTokens.Color.accent)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(document.name)
                                            .foregroundStyle(.primary)
                                            .lineLimit(1)
                                        Text("\(document.pageCount) 页")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.tertiary)
                                }
                                .frame(minHeight: 56)
                            }
                            .buttonStyle(.plain)
                            if document.id != appModel.library.documents.last?.id {
                                Divider()
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .background(.white.opacity(0.84), in: RoundedRectangle(cornerRadius: 18))
                }

                PrimaryActionButton(title: "从文件选择 PDF", state: .enabled) {
                    isImporting = true
                }
                Button("编辑模板") {
                    appModel.push(.templateEditor(template))
                }
                .buttonStyle(.bordered)
                Text("选择文件后会打开文件详情，模板参数会保留用于下一步打印。")
                    .font(.footnote)
                    .foregroundStyle(DesignTokens.Color.secondaryText)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .padding(24)
        }
        .background(DesignTokens.Color.canvas)
        .navigationTitle("套用模板")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.pdf]) { result in
            Task {
                do {
                    let source = try await appModel.pdfImportService.stage(urls: [try result.get()]).first
                    guard let source, let pdf = PDFDocument(url: source.url), pdf.pageCount > 0 else {
                        throw PDFImportService.ImportError.unableToStage
                    }
                    let values = try source.url.resourceValues(forKeys: [.fileSizeKey])
                    let record = DocumentRecord(
                        name: source.displayName,
                        pageCount: pdf.pageCount,
                        byteCount: Int64(values.fileSize ?? 0),
                        source: .files,
                        localURL: source.url
                    )
                    try appModel.library.add(record)
                    apply(to: record)
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
        .alert("无法导入文件", isPresented: .init(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("好", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "未知错误")
        }
    }

    private func apply(to document: DocumentRecord) {
        appModel.transientMessage = "已套用模板：\(template.name)"
        appModel.push(.document(document.id))
    }
}

private enum TemplateStore {
    private static let key = "print-assistant.templates"

    static func load() -> [PrintTemplate] {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let stored = try? JSONDecoder().decode([PrintTemplate].self, from: data),
            !stored.isEmpty
        else {
            return PrintTemplate.defaults
        }
        return stored
    }

    static func upsert(_ template: PrintTemplate) {
        var values = load()
        values.removeAll { $0.id == template.id }
        values.insert(template, at: 0)
        if let data = try? JSONEncoder().encode(values) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
