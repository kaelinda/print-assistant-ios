import Foundation

struct RecentSearchStore {
    static let storageKey = "print-assistant.recent-searches"
    static let limit = 8

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var queries: [String] {
        defaults.stringArray(forKey: Self.storageKey) ?? []
    }

    func remember(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var current = queries.filter { $0.caseInsensitiveCompare(trimmed) != .orderedSame }
        current.insert(trimmed, at: 0)
        if current.count > Self.limit {
            current = Array(current.prefix(Self.limit))
        }
        defaults.set(current, forKey: Self.storageKey)
    }

    func clear() {
        defaults.removeObject(forKey: Self.storageKey)
    }
}
