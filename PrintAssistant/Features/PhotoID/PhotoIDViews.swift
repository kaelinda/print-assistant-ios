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
                .font(.system(size: 54))
                .foregroundStyle(DesignTokens.Color.accent)
            Text("证件照来源").font(.title2.bold())
            Text("选择一张照片，裁剪成 1 寸证件照并排版到 A4。")
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
        } message: { Text(errorMessage ?? "未知错误") }
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
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 260)
                        .clipped()
                        .overlay { Rectangle().stroke(DesignTokens.Color.accent, lineWidth: 2) }
                }
                Text("保持头部居中，背景尽量均匀。")
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
                    .font(.system(size: 48))
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
                Text("A4 · 6 张 · \(draft.background.displayName)").foregroundStyle(.secondary)
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
            let filename = "证件照-\(Int(Date.now.timeIntervalSince1970)).pdf"
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
            appModel.replaceTop(with: .photoIDSuccess(record.id))
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct PhotoIDSuccessView: View {
    @Environment(AppModel.self) private var appModel
    let documentID: DocumentRecord.ID

    var body: some View {
        if let document = appModel.library.document(id: documentID) {
            VStack(spacing: 18) {
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 62))
                    .foregroundStyle(DesignTokens.Color.success)
                Text("证件照已生成").font(.title2.bold())
                Text("A4 · 6 张 · 文件已保存到本机").foregroundStyle(.secondary)
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
