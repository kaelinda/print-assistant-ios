import SwiftUI

struct DocumentRow: View {
    let document: DocumentRecord

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(DesignTokens.Color.accent)
                .frame(width: 36)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                Text(document.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text("\(document.pageCount) 页 · \(document.byteCount.formatted(.byteCount(style: .file)))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(document.modifiedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .contentShape(.rect)
        .frame(minHeight: 56)
        .accessibilityElement(children: .combine)
    }

    private var icon: String {
        switch document.source {
        case .scan: "doc.viewfinder"
        case .photos: "photo.on.rectangle.angled"
        case .files: "doc"
        case .generated: "doc.badge.gearshape"
        }
    }
}
