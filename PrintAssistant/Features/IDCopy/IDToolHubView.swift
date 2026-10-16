import SwiftUI

struct IDToolHubView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                Text("选择要完成的证件处理任务")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(DesignTokens.Color.primaryText)
                    .padding(.horizontal, 4)

                GlassCard(cornerRadius: 24) {
                    VStack(spacing: 0) {
                        toolRow(
                            title: "身份证复印",
                            subtitle: "拍摄人像面和国徽面，排版到 A4",
                            systemImage: "person.text.rectangle",
                            tint: DesignTokens.Color.warning
                        ) {
                            appModel.push(.idCopyCapture(.init(), .front))
                        }
                        Divider().padding(.leading, 82)
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

                infoCallout
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 24)
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
            HStack(alignment: .center, spacing: 16) {
                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 48, height: 48)
                    .background(tint.opacity(0.13), in: RoundedRectangle(cornerRadius: 14))
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(DesignTokens.Color.primaryText)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(DesignTokens.Color.secondaryText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DesignTokens.Color.tertiaryText)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    private var infoCallout: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .font(.subheadline)
                .foregroundStyle(DesignTokens.Color.accent)

            Text("处理完成后，文件会保存到本机文件库，可继续预览、分享或打印。")
                .font(.footnote)
                .foregroundStyle(DesignTokens.Color.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            DesignTokens.Color.stateSurface.opacity(0.55),
            in: RoundedRectangle(cornerRadius: 16)
        )
    }
}
