import Foundation
import Testing
@testable import PrintAssistant

struct RecentSearchStoreTests {
    @Test
    func remembersNewestFirstAndDedupesIgnoringCase() {
        let defaults = makeDefaults()
        let store = RecentSearchStore(defaults: defaults)

        store.remember("  租赁合同 ")
        store.remember("身份证")
        store.remember("租赁合同")
        store.remember("   ")

        #expect(store.queries == ["租赁合同", "身份证"])
    }

    @Test
    func keepsAtMostEightQueries() {
        let defaults = makeDefaults()
        let store = RecentSearchStore(defaults: defaults)

        for index in 0..<10 {
            store.remember("q\(index)")
        }

        #expect(store.queries.count == RecentSearchStore.limit)
        #expect(store.queries.first == "q9")
        #expect(store.queries.last == "q2")
    }

    @Test
    func clearRemovesTheStoredKey() {
        let suite = "recent-search-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let store = RecentSearchStore(defaults: defaults)
        store.remember("报销")
        store.clear()

        #expect(store.queries.isEmpty)
        #expect(defaults.object(forKey: RecentSearchStore.storageKey) == nil)
        defaults.removePersistentDomain(forName: suite)
    }

    private func makeDefaults() -> UserDefaults {
        let suite = "recent-search-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }
}
