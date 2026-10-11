import Foundation

struct BatchJob: Identifiable, Hashable, Sendable {
    struct Item: Identifiable, Hashable, Sendable {
        enum State: Hashable, Sendable {
            case pending
            case running
            case succeeded(DocumentRecord.ID)
            case failed(String)
            case cancelled
        }

        let id: DocumentRecord.ID
        var name: String
        var state: State

        init(id: DocumentRecord.ID, name: String, state: State = .pending) {
            self.id = id
            self.name = name
            self.state = state
        }
    }

    let id: UUID
    var items: [Item]
    var isCancelled: Bool

    init(id: UUID = UUID(), items: [Item], isCancelled: Bool = false) {
        self.id = id
        self.items = items
        self.isCancelled = isCancelled
    }

    var succeededIDs: [DocumentRecord.ID] {
        items.compactMap { item in
            if case .succeeded(let id) = item.state { return id }
            return nil
        }
    }

    var finishedCount: Int {
        items.filter { item in
            switch item.state {
            case .succeeded, .failed, .cancelled: true
            case .pending, .running: false
            }
        }.count
    }

    var progress: Double {
        guard !items.isEmpty else { return 0 }
        return Double(finishedCount) / Double(items.count)
    }

    mutating func markRunning(_ id: DocumentRecord.ID) {
        update(id) { $0 = .running }
    }

    mutating func markSucceeded(_ id: DocumentRecord.ID, result: DocumentRecord.ID) {
        update(id) { $0 = .succeeded(result) }
    }

    mutating func markFailed(_ id: DocumentRecord.ID, message: String) {
        update(id) { $0 = .failed(message) }
    }

    mutating func cancelRemaining() {
        isCancelled = true
        for index in items.indices {
            switch items[index].state {
            case .pending, .running:
                items[index].state = .cancelled
            case .succeeded, .failed, .cancelled:
                break
            }
        }
    }

    private mutating func update(_ id: DocumentRecord.ID, _ change: (inout Item.State) -> Void) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        change(&items[index].state)
    }
}
