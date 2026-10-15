import SwiftUI

struct ToolOrderEditorView: View {
    @Environment(AppModel.self) private var appModel

    private let orderStore: ToolOrderStore
    @State private var orderedIDs: [ToolGroup: [ToolID]]
    @State private var editMode: EditMode = .active

    init(orderStore: ToolOrderStore = .init()) {
        self.orderStore = orderStore
        _orderedIDs = State(initialValue: orderStore.load())
    }

    var body: some View {
        List {
            Section {
                Text("仅调整组内顺序")
                    .font(.footnote)
                    .foregroundStyle(DesignTokens.Color.secondaryText)
                    .listRowBackground(Color.clear)
                    .accessibilityIdentifier("tool-order-helper")
            }

            ForEach(ToolGroup.allCases, id: \.self) { group in
                Section {
                    ForEach(orderedIDs[group, default: []], id: \.self) { id in
                        orderRow(id, in: group)
                    }
                    .onMove { offsets, destination in
                        move(offsets, in: group, to: destination)
                    }
                } header: {
                    Text(LocalizedStringKey(stringLiteral: group.title))
                }
            }
        }
        .listStyle(.insetGrouped)
        .environment(\.editMode, $editMode)
        .navigationTitle("调整工具顺序")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("完成") {
                    saveAndClose()
                }
                .fontWeight(.semibold)
                .accessibilityIdentifier("tool-order-done")
            }
        }
    }

    private func orderRow(_ id: ToolID, in group: ToolGroup) -> some View {
        let entry = ToolCatalog.entry(for: id)
        return HStack(spacing: 12) {
            Image(systemName: entry.systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(entry.tint)
                .frame(width: 34, height: 34)
                .background(entry.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                Text(LocalizedStringKey(stringLiteral: entry.title))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DesignTokens.Color.primaryText)
                Text(LocalizedStringKey(stringLiteral: entry.subtitle))
                    .font(.caption)
                    .foregroundStyle(DesignTokens.Color.secondaryText)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)
        }
        .frame(minHeight: 58)
        .accessibilityIdentifier("tool-order-row-\(id.rawValue)")
        .accessibilityLabel(Text("\(group.title)，\(entry.title)"))
        .accessibilityHint(Text("可拖移排序"))
    }

    private func move(_ offsets: IndexSet, in group: ToolGroup, to destination: Int) {
        var ids = orderedIDs[group, default: []]
        ids.move(fromOffsets: offsets, toOffset: destination)
        orderedIDs[group] = ids
    }

    private func saveAndClose() {
        orderStore.save(orderedIDs)
        appModel.transientMessage = "工具顺序已保存"
        if !appModel.path.isEmpty {
            appModel.path.removeLast()
        }
    }
}
