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
                        .white.opacity(0.38),
                        .white.opacity(0.12),
                        Color(red: 217 / 255, green: 229 / 255, blue: 1).opacity(0.08)
                    ],
                    startPoint: .bottomLeading,
                    endPoint: .topTrailing
                ),
                in: RoundedRectangle(cornerRadius: cornerRadius)
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(.white.opacity(0.78), lineWidth: 1)
            }
            .shadow(color: Color(red: 20 / 255, green: 26 / 255, blue: 41 / 255).opacity(0.13), radius: 15, y: 10)
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
            Circle().stroke(.white.opacity(0.34), lineWidth: 0.75)
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
            .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(.white.opacity(0.92), lineWidth: 1)
            }
    }
}

struct GlassSearchField: View {
    @Binding var text: String
    let prompt: String

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(DesignTokens.Color.primaryText)
            TextField(prompt, text: $text)
                .font(.system(size: 14))
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
        .frame(height: 48)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay { Capsule().stroke(.white.opacity(0.78), lineWidth: 1) }
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
                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? DesignTokens.Color.primaryText : DesignTokens.Color.secondaryText)
                .padding(.horizontal, 16)
                .frame(height: 36)
                .background(isSelected ? .white.opacity(0.88) : .clear, in: Capsule())
                .overlay { Capsule().stroke(.white.opacity(isSelected ? 0.92 : 0.65), lineWidth: 1) }
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
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 40, height: 40)
                    .background(tint.opacity(0.13), in: RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(DesignTokens.Color.primaryText)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(DesignTokens.Color.secondaryText)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(DesignTokens.Color.tertiaryText)
            }
            .padding(.horizontal, 16)
            .frame(height: 72)
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
                .font(.system(size: 17, weight: .semibold))
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

    var body: some View {
        HStack(spacing: 10) {
            GlassSurface(cornerRadius: 32) {
                HStack(spacing: 0) {
                    tab(.recent, title: "最近", systemImage: "clock")
                    tab(.files, title: "文件", systemImage: "folder")
                    tab(.tools, title: "工具", systemImage: "slider.horizontal.3")
                }
                .padding(6)
                .frame(width: 280, height: 64)
            }

            Button {
                appModel.selectedTab = .search
                appModel.popToRoot()
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(DesignTokens.Color.primaryText)
                    .frame(width: 64, height: 64)
            }
            .buttonStyle(.plain)
            .background(.ultraThinMaterial, in: Circle())
            .overlay { Circle().stroke(.white.opacity(0.72), lineWidth: 1) }
            .shadow(color: Color(red: 20 / 255, green: 26 / 255, blue: 41 / 255).opacity(0.07), radius: 5, y: 3)
            .accessibilityLabel("搜索")
        }
        .frame(maxWidth: .infinity)
        .frame(height: 68)
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private func tab(_ tab: AppModel.Tab, title: String, systemImage: String) -> some View {
        Button {
            appModel.selectedTab = tab
            appModel.popToRoot()
        } label: {
            VStack(spacing: 2) {
                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .medium))
                Text(title)
                    .font(.system(size: 10, weight: appModel.selectedTab == tab ? .bold : .regular))
            }
            .foregroundStyle(appModel.selectedTab == tab ? DesignTokens.Color.primaryText : DesignTokens.Color.tertiaryText)
            .frame(width: 86, height: 52)
            .background {
                if appModel.selectedTab == tab {
                    Capsule()
                        .fill(.white.opacity(0.56))
                        .overlay { Capsule().stroke(.white.opacity(0.72), lineWidth: 1) }
                        .shadow(color: Color(red: 20 / 255, green: 26 / 255, blue: 41 / 255).opacity(0.07), radius: 5, y: 3)
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
            Capsule().stroke(.white.opacity(0.28), lineWidth: 0.75)
        }
        .disabled(state != .enabled)
        .animation(DesignTokens.Motion.fast, value: state)
    }
}
