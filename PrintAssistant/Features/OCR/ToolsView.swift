import SwiftUI

struct ToolsView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        List {
            Section("文字与识别") {
                Button {
                    appModel.push(.ocrSource)
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                            Text("文字识别")
                                .foregroundStyle(.primary)
                            Text("从照片、PDF 或相机提取可复制文字")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "text.viewfinder")
                            .foregroundStyle(DesignTokens.Color.accent)
                    }
                }
                .frame(minHeight: DesignTokens.minimumHitTarget)
            }

            Section("即将实现") {
                Label("图片转 PDF", systemImage: "photo.on.rectangle.angled")
                Label("PDF 工具箱", systemImage: "doc.on.doc")
                Label("证件与打印", systemImage: "person.text.rectangle")
            }
            .foregroundStyle(.secondary)
        }
        .navigationTitle("工具")
    }
}
