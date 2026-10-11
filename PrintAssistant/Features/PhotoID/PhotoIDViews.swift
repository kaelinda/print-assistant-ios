import PhotosUI
import SwiftUI
import VisionKit

struct PhotoIDSourceView: View {
    @Environment(AppModel.self) private var appModel
    @State private var photoItem: PhotosPickerItem?
    @State private var isCameraPresented = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "person.crop.rectangle")
                .font(.largeTitle)
                .foregroundStyle(DesignTokens.Color.accent)
            Text("证件照来源").font(.title2.bold())
            Text("选择一张照片，按 1 寸或 2 寸裁剪后排版到 A4。")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            PhotosPicker(selection: $photoItem, matching: .images) {
                Label("从照片选择", systemImage: "photo")
                    .frame(maxWidth: .infinity, minHeight: 52)
            }
            .buttonStyle(.borderedProminent)
            Button {
                isCameraPresented = true
            } label: {
                Label("打开相机拍摄", systemImage: "camera")
                    .frame(maxWidth: .infinity, minHeight: 52)
            }
            .buttonStyle(.bordered)
            Spacer()
        }
        .padding(24)
        .navigationTitle("证件照来源")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task {
                do {
                    guard let data = try await item.loadTransferable(type: Data.self) else {
                        throw CocoaError(.fileReadCorruptFile)
                    }
                    appModel.push(.photoIDCrop(.init(data: data, sizeName: "1 寸", background: .white)))
                    photoItem = nil
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
        .fullScreenCover(isPresented: $isCameraPresented) {
            DocumentCameraView(
                onComplete: { images in
                    isCameraPresented = false
                    guard let image = images.first, let data = image.jpegData(compressionQuality: 0.94) else { return }
                    appModel.push(.photoIDCrop(.init(data: data, sizeName: "1 寸", background: .white)))
                },
                onCancel: { isCameraPresented = false },
                onFailure: { error in
                    isCameraPresented = false
                    errorMessage = error.localizedDescription
                }
            )
            .ignoresSafeArea()
        }
        .alert("无法读取照片", isPresented: .init(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("好", role: .cancel) {}
        } message: { Text(errorMessage ?? String(localized: "未知错误")) }
    }
}

struct PhotoIDCropView: View {
    @Environment(AppModel.self) private var appModel
    @State private var draft: PhotoIDDraft

    init(draft: PhotoIDDraft) {
        _draft = State(initialValue: draft)
    }

    var body: some View {
        Form {
            Section("裁剪预览") {
                if let image = UIImage(data: draft.data) {
                    PhotoIDCropCanvas(
                        image: image,
                        spec: PhotoIDGeometry.spec(for: draft.sizeName),
                        offset: $draft.cropOffset
                    )
                    .frame(height: 280)
                    .accessibilityLabel("拖动调整裁剪")
                }
                Text("拖动照片调整位置。裁剪框按所选寸照比例取景。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Section("证件照规格") {
                Picker("尺寸", selection: $draft.sizeName) {
                    Text("1 寸").tag("1 寸")
                    Text("2 寸").tag("2 寸")
                }
                Picker("背景", selection: $draft.background) {
                    ForEach(PhotoIDDraft.PhotoIDBackground.allCases, id: \.self) {
                        Text($0.displayName).tag($0)
                    }
                }
            }
            Section {
                PrimaryActionButton(title: "生成证件照 PDF", state: .enabled) {
                    appModel.push(.photoIDGenerating(draft))
                }
            }
            .listRowInsets(.init())
            .listRowBackground(Color.clear)
        }
        .navigationTitle("证件照裁剪")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PhotoIDGeneratingView: View {
    @Environment(AppModel.self) private var appModel
    let draft: PhotoIDDraft
    @State private var errorMessage: String?
    @State private var attempt = 0

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            if let errorMessage {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundStyle(DesignTokens.Color.warning)
                Text("证件照生成失败").font(.title2.bold())
                Text(errorMessage).multilineTextAlignment(.center).foregroundStyle(.secondary)
                PrimaryActionButton(title: "重试", state: .enabled) {
                    self.errorMessage = nil
                    attempt += 1
                }
            } else {
                ProgressView().controlSize(.large)
                Text("正在排版证件照").font(.title2.bold())
                Text("A4 · \(PhotoIDGeometry.spec(for: draft.sizeName).sheetCount) 张 · \(draft.background.displayName)").foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(24)
        .navigationTitle("生成证件照")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: attempt) {
            guard errorMessage == nil else { return }
            await generate()
        }
    }

    @MainActor
    private func generate() async {
        do {
            let filename = AppCopy.datedPDF(String(localized: "证件照"))
            let url = try await appModel.pdfService.makePhotoIDPDF(from: draft, filename: filename)
            let values = try url.resourceValues(forKeys: [.fileSizeKey])
            let record = DocumentRecord(
                name: filename,
                pageCount: 1,
                byteCount: Int64(values.fileSize ?? 0),
                source: .generated,
                localURL: url
            )
            try appModel.library.add(record)
            let sheetCount = PhotoIDGeometry.spec(for: draft.sizeName).sheetCount
            appModel.replaceTop(with: .photoIDSuccess(record.id, sheetCount: sheetCount))
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct PhotoIDSuccessView: View {
    @Environment(AppModel.self) private var appModel
    let documentID: DocumentRecord.ID
    let sheetCount: Int

    var body: some View {
        if let document = appModel.library.document(id: documentID) {
            VStack(spacing: 18) {
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(DesignTokens.Color.success)
                Text("证件照已生成").font(.title2.bold())
                Text("A4 · \(sheetCount) 张 · 文件已保存到本机").foregroundStyle(.secondary)
                PrimaryActionButton(title: "预览 / 分享", state: .enabled) {
                    appModel.push(.pdfPreview(document.id))
                }
                Button("返回最近") {
                    appModel.selectedTab = .recent
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

private struct PhotoIDCropCanvas: View {
    let image: UIImage
    let spec: PhotoIDGeometry.Spec
    @Binding var offset: CGSize
    @State private var gestureOrigin: CGSize = .zero

    var body: some View {
        GeometryReader { geo in
            let frame = frameSize(in: geo.size, aspect: spec.cardSize)
            let displayed = displayedSize(imageSize: image.size, frame: frame)
            let limit = CGSize(
                width: max(0, (displayed.width - frame.width) / 2),
                height: max(0, (displayed.height - frame.height) / 2)
            )
            Image(uiImage: image)
                .resizable()
                .frame(width: displayed.width, height: displayed.height)
                .offset(visualOffset(offset, limit: limit))
                .frame(width: frame.width, height: frame.height)
                .clipped()
                .overlay { Rectangle().stroke(DesignTokens.Color.accent, lineWidth: 2) }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .highPriorityGesture(
                    DragGesture()
                        .onChanged { value in
                            offset = clampedOffset(start: gestureOrigin, translation: value.translation, limit: limit)
                        }
                        .onEnded { _ in
                            gestureOrigin = offset
                        }
                )
                .onAppear { gestureOrigin = offset }
        }
    }

    private func frameSize(in container: CGSize, aspect: CGSize) -> CGSize {
        guard aspect.width > 0, aspect.height > 0, container.width > 0, container.height > 0 else {
            return container
        }
        let target = aspect.width / aspect.height
        let available = container.width / container.height
        if available > target {
            return CGSize(width: container.height * target, height: container.height)
        }
        return CGSize(width: container.width, height: container.width / target)
    }

    private func displayedSize(imageSize: CGSize, frame: CGSize) -> CGSize {
        guard imageSize.width > 0, imageSize.height > 0, frame.width > 0, frame.height > 0 else {
            return frame
        }
        let scale = max(frame.width / imageSize.width, frame.height / imageSize.height)
        return CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
    }

    private func visualOffset(_ offset: CGSize, limit: CGSize) -> CGSize {
        CGSize(
            width: -min(1, max(-1, offset.width)) * limit.width,
            height: -min(1, max(-1, offset.height)) * limit.height
        )
    }

    private func clampedOffset(start: CGSize, translation: CGSize, limit: CGSize) -> CGSize {
        let dx = limit.width > 0 ? -translation.width / limit.width : 0
        let dy = limit.height > 0 ? -translation.height / limit.height : 0
        return CGSize(
            width: min(1, max(-1, start.width + dx)),
            height: min(1, max(-1, start.height + dy))
        )
    }
}
