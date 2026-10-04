import UIKit

struct ScanDraft: Hashable {
    let id = UUID()
    var pages: [UIImage]

    static func == (lhs: ScanDraft, rhs: ScanDraft) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
