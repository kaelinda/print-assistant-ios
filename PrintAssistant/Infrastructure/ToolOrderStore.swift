import Foundation

final class ToolOrderStore {
    static let storageKey = "print-assistant.tool-order"
    private static let currentVersion = 1

    private struct Payload: Codable {
        let version: Int
        let groups: [String: [String]]
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> [ToolGroup: [ToolID]] {
        guard
            let data = defaults.data(forKey: Self.storageKey),
            let payload = try? JSONDecoder().decode(Payload.self, from: data),
            payload.version == Self.currentVersion
        else {
            return ToolCatalog.defaultOrder
        }

        return normalizedOrder(from: payload.groups)
    }

    func save(_ order: [ToolGroup: [ToolID]]) {
        let normalized = normalizedOrder(from: order.reduce(into: [String: [String]]()) { result, item in
            result[item.key.rawValue] = item.value.map(\.rawValue)
        })
        let groups = ToolGroup.allCases.reduce(into: [String: [String]]()) { result, group in
            result[group.rawValue] = normalized[group, default: []].map(\.rawValue)
        }
        let payload = Payload(version: Self.currentVersion, groups: groups)
        guard let data = try? JSONEncoder().encode(payload) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }

    private func normalizedOrder(from groups: [String: [String]]) -> [ToolGroup: [ToolID]] {
        ToolGroup.allCases.reduce(into: [ToolGroup: [ToolID]]()) { result, group in
            var seen = Set<ToolID>()
            var ids: [ToolID] = []
            let storedIDs = groups[group.rawValue, default: []]

            for rawID in storedIDs {
                guard
                    let id = ToolID(rawValue: rawID),
                    ToolCatalog.group(for: id) == group,
                    seen.insert(id).inserted
                else { continue }
                ids.append(id)
            }

            for id in ToolCatalog.defaultOrder[group, default: []]
                where seen.insert(id).inserted {
                ids.append(id)
            }
            result[group] = ids
        }
    }
}
