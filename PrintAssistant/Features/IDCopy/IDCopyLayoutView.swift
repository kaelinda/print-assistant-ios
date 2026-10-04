import SwiftUI

struct IDCopyLayoutView: View {
    @Environment(AppModel.self) private var appModel
    let draft: IDCopyDraft

    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                Text("A4 · 实际尺寸")
                    .font(.headline)

                GeometryReader { proxy in
                    let a4 = PhysicalPrintGeometry.a4Size
                    let scale = min(proxy.size.width / a4.width, proxy.size.height / a4.height)
                    let pageSize = CGSize(width: a4.width * scale, height: a4.height * scale)
                    let cardSize = CGSize(
                        width: PhysicalPrintGeometry.id1CardSize.width * scale,
                        height: PhysicalPrintGeometry.id1CardSize.height * scale
                    )

                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.white)
                            .shadow(color: .black.opacity(0.10), radius: 14, y: 7)

                        VStack(spacing: PhysicalPrintGeometry.points(millimeters: 20) * scale) {
                            cardPreview(data: draft.frontData, label: "人像面")
                                .frame(width: cardSize.width, height: cardSize.height)
                            cardPreview(data: draft.backData, label: "国徽面")
                                .frame(width: cardSize.width, height: cardSize.height)
                        }
                    }
                    .frame(width: pageSize.width, height: pageSize.height)
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                }
                .frame(height: 520)

                VStack(spacing: DesignTokens.Spacing.xs) {
                    Text("85.60 × 53.98 mm")
                        .font(.headline.monospacedDigit())
                    Text("PDF 中的证件外框按 ID‑1 标准尺寸生成。最终纸面尺寸仍需打印时选择 100% / 实际大小，并以真机打印验证为准。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                PrimaryActionButton(
                    title: "生成 A4 PDF",
                    state: draft.isComplete ? .enabled : .disabled
                ) {
                    appModel.push(.idCopyGenerating(draft))
                }
            }
            .padding(DesignTokens.Spacing.lg)
        }
        .navigationTitle("身份证排版")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func cardPreview(data: Data?, label: String) -> some View {
        if let data, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .background(.white)
                .overlay {
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(.black.opacity(0.10), lineWidth: 0.5)
                }
                .accessibilityLabel(label)
        } else {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.secondary.opacity(0.08))
                .overlay { Text(label).font(.caption).foregroundStyle(.secondary) }
        }
    }
}
