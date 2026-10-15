import SwiftUI

struct ToolsView: View {
    @Environment(AppModel.self) private var appModel

    private let orderStore: ToolOrderStore
    @State private var orderedIDs: [ToolGroup: [ToolID]]

    init(orderStore: ToolOrderStore = .init()) {
        self.orderStore = orderStore
        _orderedIDs = State(initialValue: orderStore.load())
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 10) {
                    Text("工具")
                        .font(.largeTitle.bold())
                        .foregroundStyle(DesignTokens.Color.primaryText)
                    Spacer()
                    GlassIconButton {
                        appModel.push(.toolOrderEditor)
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(DesignTokens.Color.primaryText)
                    }
                    .accessibilityLabel("调整顺序")
                    .accessibilityIdentifier("tool-order-edit")
                    GlassIconButton {
                        appModel.push(.settings)
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(DesignTokens.Color.primaryText)
                    }
                    .accessibilityLabel("更多工具")
                    .accessibilityIdentifier("open-settings")
                }
                .frame(minHeight: 52)

                ForEach(ToolGroup.allCases, id: \.self) { group in
                    toolSection(group)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 120)
        }
        .background(DesignTokens.Color.canvas)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            orderedIDs = orderStore.load()
        }
    }

    @ViewBuilder
    private func toolSection(_ group: ToolGroup) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            GlassSectionHeader(LocalizedStringKey(stringLiteral: group.title))
            GlassCard(cornerRadius: 20) {
                VStack(spacing: 0) {
                    let ids = orderedIDs[group, default: []]
                    ForEach(Array(ids.enumerated()), id: \.element) { index, id in
                        let entry = ToolCatalog.entry(for: id)
                        GlassActionRow(
                            title: LocalizedStringKey(stringLiteral: entry.title),
                            subtitle: LocalizedStringKey(stringLiteral: entry.subtitle),
                            systemImage: entry.systemImage,
                            tint: entry.tint
                        ) {
                            appModel.push(entry.route)
                        }
                        .accessibilityIdentifier("tool-row-\(id.rawValue)")
                        if index < ids.count - 1 {
                            Divider().padding(.leading, 70)
                        }
                    }
                }
            }
        }
    }
}
