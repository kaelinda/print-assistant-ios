import SwiftUI

struct GlassSurface<Content: View>: View {
    let cornerRadius: CGFloat
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
            .background(
                LinearGradient(
                    colors: [
                        DesignTokens.Color.hairline.opacity(0.5),
                        DesignTokens.Color.cardFill.opacity(0.4),
                        DesignTokens.Color.stateSurface.opacity(0.35)
                    ],
                    startPoint: .bottomLeading,
                    endPoint: .topTrailing
                ),
                in: RoundedRectangle(cornerRadius: cornerRadius)
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(DesignTokens.Color.hairline, lineWidth: 1)
            }
            .shadow(color: DesignTokens.Color.shadow, radius: 15, y: 10)
    }
}

struct GlassIconButton<Label: View>: View {
    let action: () -> Void
    @ViewBuilder var label: () -> Label

    var body: some View {
        Button(action: action) {
            label()
                .frame(width: DesignTokens.minimumHitTarget, height: DesignTokens.minimumHitTarget)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .background(.regularMaterial, in: Circle())
        .overlay {
            Circle().stroke(DesignTokens.Color.hairline, lineWidth: 0.75)
        }
        .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
        .accessibilityAddTraits(.isButton)
    }
}

struct GlassCard<Content: View>: View {
    let cornerRadius: CGFloat
    @ViewBuilder var content: () -> Content

    init(cornerRadius: CGFloat = DesignTokens.Radius.card, @ViewBuilder content: @escaping () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content
    }

    var body: some View {
        content()
            .background(DesignTokens.Color.cardFill, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(DesignTokens.Color.hairline, lineWidth: 1)
            }
    }
}

struct GlassSearchField: View {
    @Binding var text: String
    let prompt: String

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            Image(systemName: "magnifyingglass")
                .font(.body.weight(.medium))
                .foregroundStyle(DesignTokens.Color.primaryText)
            TextField(prompt, text: $text)
                .font(.subheadline)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(DesignTokens.Color.tertiaryText)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 48)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay { Capsule().stroke(DesignTokens.Color.hairline, lineWidth: 1) }
        .shadow(color: Color.black.opacity(0.08), radius: 12, y: 7)
    }
}

struct GlassChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.footnote.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? DesignTokens.Color.primaryText : DesignTokens.Color.secondaryText)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .frame(minHeight: 36)
                .background(isSelected ? DesignTokens.Color.cardFill : .clear, in: Capsule())
                .overlay { Capsule().stroke(DesignTokens.Color.hairline, lineWidth: 1) }
        }
        .buttonStyle(.plain)
    }
}

struct GlassActionRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: SwiftUI.Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.headline)
                    .foregroundStyle(tint)
                    .frame(width: 40, height: 40)
                    .background(tint.opacity(0.13), in: RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(DesignTokens.Color.primaryText)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(DesignTokens.Color.secondaryText)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(DesignTokens.Color.tertiaryText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(minHeight: 72)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

struct GlassSectionHeader<Trailing: View>: View {
    let title: String
    @ViewBuilder var trailing: () -> Trailing

    init(_ title: String, @ViewBuilder trailing: @escaping () -> Trailing) {
        self.title = title
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.headline)
                .foregroundStyle(DesignTokens.Color.primaryText)
            Spacer()
            trailing()
        }
    }
}

extension GlassSectionHeader where Trailing == EmptyView {
    init(_ title: String) {
        self.init(title) { EmptyView() }
    }
}

struct GlassTabBar: View {
    @Environment(AppModel.self) private var appModel
    @ScaledMetric(relativeTo: .title2) private var searchSide: CGFloat = 64

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            GlassSurface(cornerRadius: 32) {
                HStack(spacing: 0) {
                    tab(.recent, title: "最近", systemImage: "clock")
                    tab(.files, title: "文件", systemImage: "folder")
                    tab(.tools, title: "工具", systemImage: "slider.horizontal.3")
                }
                .padding(6)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 64)
            }

            Button {
                appModel.selectedTab = .search
                appModel.popToRoot()
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.title2)
                    .foregroundStyle(DesignTokens.Color.primaryText)
                    .frame(minWidth: searchSide, minHeight: searchSide)
            }
            .buttonStyle(.plain)
            .background(.ultraThinMaterial, in: Circle())
            .overlay { Circle().stroke(DesignTokens.Color.hairline, lineWidth: 1) }
            .shadow(color: DesignTokens.Color.shadow, radius: 5, y: 3)
            .accessibilityLabel("搜索")
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 68)
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private func tab(_ tab: AppModel.Tab, title: String, systemImage: String) -> some View {
        let isSelected = appModel.selectedTab == tab
        Button {
            appModel.selectedTab = tab
            appModel.popToRoot()
        } label: {
            VStack(spacing: 2) {
                Image(systemName: systemImage)
                    .font(.title2)
                Text(title)
                    .font(.caption2.weight(isSelected ? .bold : .regular))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(isSelected ? DesignTokens.Color.primaryText : DesignTokens.Color.tertiaryText)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .padding(.vertical, 6)
            .background {
                if isSelected {
                    Capsule()
                        .fill(DesignTokens.Color.selectedFill)
                        .overlay { Capsule().stroke(DesignTokens.Color.hairline, lineWidth: 1) }
                        .shadow(color: DesignTokens.Color.shadow, radius: 5, y: 3)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

struct PrimaryActionButton: View {
    enum State: Equatable {
        case enabled
        case disabled
        case processing
    }

    let title: String
    let state: State
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.xs) {
                if state == .processing {
                    ProgressView()
                        .tint(.white)
                }
                Text(state == .processing ? "处理中" : title)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity, minHeight: 52)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .background(
            DesignTokens.Color.accent.opacity(state == .enabled ? 1 : 0.52),
            in: Capsule()
        )
        .overlay {
            Capsule().stroke(DesignTokens.Color.hairline, lineWidth: 0.75)
        }
        .disabled(state != .enabled)
        .animation(DesignTokens.Motion.fast, value: state)
    }
}
