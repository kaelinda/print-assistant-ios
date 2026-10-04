import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct OCRSourceView: View {
    @Environment(AppModel.self) private var appModel

    @State private var photoItem: PhotosPickerItem?
    @State private var isImportingFile = false
    @State private var importError: String?
    @State private var isLoadingSelection = false

    var body: some View {
        List {
            Section {
                Button {
                    appModel.push(.ocrCamera)
                } label: {
                    sourceRow(
                        title: "拍照识别",
                        subtitle: "拍摄纸张并提取文字",
                        systemImage: "camera"
                    )
                }

                PhotosPicker(selection: $photoItem, matching: .images) {
                    sourceRow(
                        title: "从照片选择",
                        subtitle: "使用系统照片选择器",
                        systemImage: "photo"
                    )
                }
                .onChange(of: photoItem) { _, newValue in
                    guard let newValue else { return }
                    Task { await loadPhoto(newValue) }
                }

                Button {
                    isImportingFile = true
                } label: {
                    sourceRow(
                        title: "从文件选择",
                        subtitle: "支持图片和 PDF",
                        systemImage: "folder"
                    )
                }
            }

            if isLoadingSelection {
                Section {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        ProgressView()
                        Text("正在读取文件…")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                Text("识别在设备上完成。你主动选择的内容不会因为 OCR 自动上传。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("文字识别")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $isImportingFile,
            allowedContentTypes: [.image, .pdf],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .alert("无法读取文件", isPresented: .init(
            get: { importError != nil },
            set: { if !$0 { importError = nil } }
        )) {
            Button("好", role: .cancel) {}
        } message: {
            Text(importError ?? "未知错误")
        }
    }

    private func sourceRow(title: String, subtitle: String, systemImage: String) -> some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(DesignTokens.Color.accent)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                Text(title)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .contentShape(.rect)
        .frame(minHeight: DesignTokens.minimumHitTarget)
    }

    @MainActor
    private func loadPhoto(_ item: PhotosPickerItem) async {
        isLoadingSelection = true
        defer {
            isLoadingSelection = false
            photoItem = nil
        }

        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                throw CocoaError(.fileReadCorruptFile)
            }
            appModel.push(.ocrProcessing(.init(
                data: data,
                kind: .image,
                displayName: "照片"
            )))
        } catch {
            importError = error.localizedDescription
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
            let accessed = url.startAccessingSecurityScopedResource()
            defer {
                if accessed { url.stopAccessingSecurityScopedResource() }
            }

            let data = try Data(contentsOf: url)
            let kind: OCRInput.Kind = url.pathExtension.lowercased() == "pdf" ? .pdf : .image

            appModel.push(.ocrProcessing(.init(
                data: data,
                kind: kind,
                displayName: url.lastPathComponent
            )))
        } catch {
            importError = error.localizedDescription
        }
    }
}
