import SwiftUI

struct IDCopyLayoutView: View {
    @Environment(AppModel.self) private var appModel
    let draft: IDCopyDraft

    @State private var watermarkText: String

    init(draft: IDCopyDraft) {
        self.draft = draft
        _watermarkText = State(initialValue: draft.watermarkText)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                Text("A4 · 实际尺寸")
                    .font(.headline)

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text("水印文字")
                        .font(.headline)
                    TextField("此证件仅用于 xxxx", text: $watermarkText)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1)
                        .accessibilityLabel("身份证水印文字")
                        .accessibilityIdentifier("id-copy-watermark-field")
                        .onChange(of: watermarkText) { _, value in
                            let limited = String(value.prefix(IDCopyWatermarkLayout.maxLength))
                            if limited != value {
                                watermarkText = limited
                            }
                        }
                    Text("水印会以浅色斜向文字显示在 PDF 上，可留空。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

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
                            .shadow(color: DesignTokens.Color.shadow.opacity(0.76), radius: 14, y: 7)

                        VStack(spacing: PhysicalPrintGeometry.points(millimeters: 20) * scale) {
                            cardPreview(data: draft.frontData, label: "人像面")
                                .frame(width: cardSize.width, height: cardSize.height)
                            cardPreview(data: draft.backData, label: "国徽面")
                                .frame(width: cardSize.width, height: cardSize.height)
                        }

                        if let watermarkText = IDCopyWatermarkLayout.normalized(watermarkText) {
                            IDCopyWatermarkPreview(
                                text: watermarkText,
                                pageSize: pageSize,
                                scale: scale
                            )
                        }
                    }
                    .frame(width: pageSize.width, height: pageSize.height)
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                }
                .frame(height: 520)

                VStack(spacing: DesignTokens.Spacing.xs) {
                    Text(verbatim: AppCopy.id1CardSize)
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
                    var updatedDraft = draft
                    updatedDraft.watermarkText = watermarkText
                    appModel.push(.idCopyGenerating(updatedDraft))
                }
            }
            .padding(DesignTokens.Spacing.lg)
        }
        .navigationTitle("身份证排版")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func cardPreview(data: Data?, label: LocalizedStringKey) -> some View {
        if let data, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .background(.white)
                .overlay {
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(DesignTokens.Color.shadow.opacity(0.76), lineWidth: 0.5)
                }
                .accessibilityLabel(label)
        } else {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.secondary.opacity(0.08))
                .overlay { Text(label).font(.caption).foregroundStyle(.secondary) }
        }
    }
}

private struct IDCopyWatermarkPreview: View {
    let text: String
    let pageSize: CGSize
    let scale: CGFloat

    var body: some View {
        ZStack {
            ForEach(-3...3, id: \.self) { row in
                ForEach(-2...2, id: \.self) { column in
                    Text(text)
                        .font(.system(
                            size: IDCopyWatermarkLayout.fontSize * scale,
                            weight: .semibold
                        ))
                        .foregroundStyle(.gray.opacity(IDCopyWatermarkLayout.opacity))
                        .fixedSize()
                        .position(
                            x: pageSize.width / 2 + CGFloat(column) * IDCopyWatermarkLayout.columnSpacing * scale,
                            y: pageSize.height / 2 + CGFloat(row) * IDCopyWatermarkLayout.rowSpacing * scale
                        )
                }
            }
        }
        .frame(width: pageSize.width, height: pageSize.height)
        .rotationEffect(.degrees(IDCopyWatermarkLayout.angleDegrees))
        .clipped()
        .allowsHitTesting(false)
    }
}
