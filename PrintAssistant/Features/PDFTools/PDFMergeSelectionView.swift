import SwiftUI
import UniformTypeIdentifiers

struct PDFMergeSelectionView: View {
    @Environment(AppModel.self) private var appModel

    @State private var selected: [PDFSourceItem] = []
    @State private var isImporting = false
    @State private var isStaging = false
    @State private var errorMessage: String?
    @State private var isNavigatingForward = false

    var body: some View {
        VStack(spacing: 0) {
            List {
                if !selected.isEmpty {
                    Section("合并顺序") {
                        ForEach(selected) { item in
                            HStack {
                                Image(systemName: "line.3.horizontal")
                                    .foregroundStyle(.tertiary)
                                    .accessibilityHidden(true)
                                Text(item.displayName)
                                    .lineLimit(2)
                                Spacer()
                                Button {
                                    remove(item)
                                } label: {
                                    Image(systemName: "minus.circle")
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("移除 \(item.displayName)")
                            }
                            .frame(minHeight: DesignTokens.minimumHitTarget)
                        }
                        .onMove { offsets, destination in
                            selected.move(fromOffsets: offsets, toOffset: destination)
                        }
                    }
                }

                Section("本机文件") {
                    if appModel.library.documents.isEmpty {
                        Text("文件库中还没有 PDF")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(appModel.library.documents) { document in
                            Button {
                                toggle(document)
                            } label: {
                                HStack {
                                    Image(systemName: isSelected(document.localURL) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(isSelected(document.localURL) ? DesignTokens.Color.accent : .secondary)
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
                        Label("从文件添加 PDF", systemImage: "folder")
                    }
                    .disabled(isStaging)

                    if isStaging {
                        HStack(spacing: DesignTokens.Spacing.sm) {
                            ProgressView()
                            Text("正在导入…")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            PrimaryActionButton(
                title: "合并 \(selected.count) 个 PDF",
                state: selected.count >= 2 && !isStaging ? .enabled : .disabled
            ) {
                isNavigatingForward = true
                appModel.push(.pdfMergeProcessing(.init(sources: selected)))
            }
            .padding(DesignTokens.Spacing.lg)
        }
        .navigationTitle("合并 PDF")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !selected.isEmpty {
                EditButton()
            }
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: true
        ) { result in
            stage(result)
        }
        .onDisappear {
            if !isNavigatingForward {
                appModel.pdfImportService.cleanup(selected)
            }
        }
        .alert("无法添加 PDF", isPresented: .init(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("好", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "未知错误")
        }
    }

    private func toggle(_ document: DocumentRecord) {
        if let index = selected.firstIndex(where: { $0.url == document.localURL }) {
            selected.remove(at: index)
        } else {
            selected.append(.init(
                url: document.localURL,
                displayName: document.name
            ))
        }
    }

    private func isSelected(_ url: URL) -> Bool {
        selected.contains { $0.url == url }
    }

    private func remove(_ item: PDFSourceItem) {
        if item.isTemporary {
            appModel.pdfImportService.cleanup([item])
        }
        selected.removeAll { $0.id == item.id }
    }

    private func stage(_ result: Result<[URL], Error>) {
        Task {
            do {
                let urls = try result.get()
                isStaging = true
                let imported = try await appModel.pdfImportService.stage(urls: urls)
                selected.append(contentsOf: imported)
                isStaging = false
            } catch {
                isStaging = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
