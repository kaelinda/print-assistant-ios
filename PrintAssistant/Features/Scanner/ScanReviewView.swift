import SwiftUI

struct ScanReviewView: View {
    @Environment(AppModel.self) private var appModel
    let draft: ScanDraft

    @State private var selectedPage = 0
    @State private var saveError: String?
    @State private var isSaving = false

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedPage) {
                ForEach(Array(draft.pages.enumerated()), id: \.offset) { index, image in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding(DesignTokens.Spacing.md)
                        .tag(index)
                        .accessibilityLabel("扫描第 \(index + 1) 页")
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack {
                Text("\(selectedPage + 1) / \(draft.pages.count)")
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(.secondary)
                Spacer()
                Text("检查边缘与清晰度")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.vertical, DesignTokens.Spacing.sm)

            PrimaryActionButton(
                title: "完成并保存",
                state: isSaving ? .processing : .enabled
            ) {
                save()
            }
            .padding(DesignTokens.Spacing.lg)
        }
        .navigationTitle("扫描结果")
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(isSaving)
        .alert("无法保存", isPresented: .init(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Button("好", role: .cancel) {}
        } message: {
            Text(saveError ?? "未知错误")
        }
    }

    private func save() {
        guard !isSaving else { return }
        isSaving = true

        do {
            let filename = "扫描文档-\(Int(Date.now.timeIntervalSince1970)).pdf"
            let url = try appModel.pdfService.makePDF(from: draft.pages, filename: filename)
            let values = try url.resourceValues(forKeys: [.fileSizeKey])
            let record = DocumentRecord(
                name: filename,
                pageCount: draft.pages.count,
                byteCount: Int64(values.fileSize ?? 0),
                source: .scan,
                localURL: url
            )
            try appModel.library.add(record)
            appModel.path = [.document(record.id)]
            appModel.transientMessage = "已保存到本机"

            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1.6))
                if appModel.transientMessage == "已保存到本机" {
                    appModel.transientMessage = nil
                }
            }
        } catch {
            isSaving = false
            saveError = error.localizedDescription
        }
    }
}
