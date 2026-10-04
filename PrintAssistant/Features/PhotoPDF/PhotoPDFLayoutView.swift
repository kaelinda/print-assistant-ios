import SwiftUI

struct PhotoPDFLayoutView: View {
    @Environment(AppModel.self) private var appModel
    @State private var draft: PhotoPDFDraft

    init(draft: PhotoPDFDraft) {
        _draft = State(initialValue: draft)
    }

    var body: some View {
        Form {
            Section("预览") {
                preview
                    .frame(maxWidth: .infinity)
                    .frame(height: 320)
                    .padding(.vertical, DesignTokens.Spacing.sm)
            }

            Section("纸张") {
                Picker("尺寸", selection: $draft.paper) {
                    ForEach(PhotoPDFDraft.Paper.allCases, id: \.self) { paper in
                        Text(paper.displayName).tag(paper)
                    }
                }

                Picker("图片适配", selection: $draft.fitMode) {
                    ForEach(PhotoPDFDraft.FitMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    HStack {
                        Text("页边距")
                        Spacer()
                        Text(marginText)
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $draft.marginPoints, in: 0...72, step: 4)
                }
            }

            Section {
                Text("每张图片生成一页 PDF，并严格按照上一页的图片顺序输出。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                PrimaryActionButton(title: "生成 PDF", state: .enabled) {
                    appModel.push(.photoPDFGenerating(draft))
                }
            }
            .listRowInsets(.init())
            .listRowBackground(Color.clear)
        }
        .navigationTitle("图片排版")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var preview: some View {
        GeometryReader { proxy in
            let page = draft.paper.sizeInPoints
            let scale = min(proxy.size.width / page.width, proxy.size.height / page.height)
            let pageSize = CGSize(width: page.width * scale, height: page.height * scale)
            let margin = draft.marginPoints * scale

            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.10), radius: 12, y: 6)

                if
                    let first = draft.items.first,
                    let image = UIImage(data: first.data)
                {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: draft.fitMode == .fit ? .fit : .fill)
                        .frame(
                            width: max(1, pageSize.width - margin * 2),
                            height: max(1, pageSize.height - margin * 2)
                        )
                        .clipped()
                }
            }
            .frame(width: pageSize.width, height: pageSize.height)
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
    }

    private var marginText: String {
        let millimeters = draft.marginPoints / 72 * 25.4
        return "\(Int(millimeters.rounded())) mm"
    }
}
