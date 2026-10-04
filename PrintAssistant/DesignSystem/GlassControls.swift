import SwiftUI

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
