import SwiftUI

struct IDToolHubView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("证件工具")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(DesignTokens.Color.primaryText)
                    Text("选择要完成的证件处理任务")
                        .font(.subheadline)
                        .foregroundStyle(DesignTokens.Color.secondaryText)
                }

                GlassCard(cornerRadius: 22) {
                    VStack(spacing: 0) {
                        toolRow(
                            title: "身份证复印",
                            subtitle: "拍摄人像面和国徽面，排版到 A4",
                            systemImage: "person.text.rectangle",
                            tint: DesignTokens.Color.warning
                        ) {
                            appModel.push(.idCopyCapture(.init(), .front))
                        }
                        Divider().padding(.leading, 70)
                        toolRow(
                            title: "证件照排版",
                            subtitle: "选择或拍摄照片，生成 1 寸证件照",
                            systemImage: "person.crop.rectangle",
                            tint: DesignTokens.Color.accent
                        ) {
                            appModel.push(.photoIDSource)
                        }
                    }
                }

                Text("处理完成后，文件会保存到本机文件库，可继续预览、分享或打印。")
                    .font(.footnote)
                    .foregroundStyle(DesignTokens.Color.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(24)
        }
        .background(DesignTokens.Color.canvas)
        .navigationTitle("证件工具")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func toolRow(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 42, height: 42)
                    .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(DesignTokens.Color.secondaryText)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(DesignTokens.Color.tertiaryText)
            }
            .frame(maxWidth: .infinity, minHeight: 78)
        }
        .buttonStyle(.plain)
    }
}
