import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct PhotoPDFSelectionView: View {
    @Environment(AppModel.self) private var appModel

    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var items: [PhotoPDFItem] = []
    @State private var isImportingFiles = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            if items.isEmpty {
                ContentUnavailableView {
                    Label("选择要转换的图片", systemImage: "photo.on.rectangle.angled")
                } description: {
                    Text("可以从照片或文件选择多张图片。PDF 页序会按照这里的顺序生成。")
                } actions: {
                    sourceActions
                }
            } else {
                List {
                    Section {
                        ForEach(items) { item in
                            HStack(spacing: DesignTokens.Spacing.sm) {
                                thumbnail(item)
                                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                                    Text(item.displayName)
                                        .lineLimit(1)
                                    Text("拖动可调整 PDF 页序")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(minHeight: 64)
                        }
                        .onMove { offsets, destination in
                            items.move(fromOffsets: offsets, toOffset: destination)
                        }
                        .onDelete { offsets in
                            items.remove(atOffsets: offsets)
                        }
                    } header: {
                        Text("已选择 \(items.count) 张")
                    }

                    Section {
                        sourceActions
                    }
                }

                PrimaryActionButton(
                    title: "下一步",
                    state: isLoading ? .processing : .enabled
                ) {
                    appModel.push(.photoPDFLayout(.init(items: items)))
                }
                .padding(DesignTokens.Spacing.lg)
            }
        }
        .navigationTitle("选择图片")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !items.isEmpty {
                EditButton()
            }
        }
        .fileImporter(
            isPresented: $isImportingFiles,
            allowedContentTypes: [.image],
            allowsMultipleSelection: true
        ) { result in
            importFiles(result)
        }
        .onChange(of: pickerItems) { _, newItems in
            guard !newItems.isEmpty else { return }
            Task { await importPhotos(newItems) }
        }
        .alert("无法读取图片", isPresented: .init(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("好", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "未知错误")
        }
    }

    @ViewBuilder
    private var sourceActions: some View {
        PhotosPicker(
            selection: $pickerItems,
            maxSelectionCount: 50,
            matching: .images
        ) {
            Label("从照片选择", systemImage: "photo")
        }

        Button {
            isImportingFiles = true
        } label: {
            Label("从文件选择", systemImage: "folder")
        }
    }

    private func thumbnail(_ item: PhotoPDFItem) -> some View {
        Group {
            if let image = UIImage(data: item.data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 52, height: 52)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .clipped()
    }

    @MainActor
    private func importPhotos(_ selections: [PhotosPickerItem]) async {
        isLoading = true
        defer {
            isLoading = false
            pickerItems = []
        }

        do {
            var imported: [PhotoPDFItem] = []
            imported.reserveCapacity(selections.count)

            for (index, selection) in selections.enumerated() {
                guard let data = try await selection.loadTransferable(type: Data.self) else {
                    throw CocoaError(.fileReadCorruptFile)
                }
                imported.append(.init(
                    data: data,
                    displayName: "照片 \(items.count + index + 1)"
                ))
            }

            items.append(contentsOf: imported)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func importFiles(_ result: Result<[URL], Error>) {
        do {
            let urls = try result.get()
            var imported: [PhotoPDFItem] = []
            imported.reserveCapacity(urls.count)

            for url in urls {
                let accessed = url.startAccessingSecurityScopedResource()
                defer {
                    if accessed { url.stopAccessingSecurityScopedResource() }
                }
                imported.append(.init(
                    data: try Data(contentsOf: url),
                    displayName: url.lastPathComponent
                ))
            }

            items.append(contentsOf: imported)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
