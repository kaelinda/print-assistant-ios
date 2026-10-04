import Foundation
import Testing
@testable import PrintAssistant

struct PhotoPDFModelsTests {
    @Test
    func a4UsesPortraitPointSize() {
        let size = PhotoPDFDraft.Paper.a4.sizeInPoints
        #expect(size.height > size.width)
        #expect(abs(size.width - 595.28) < 0.01)
    }

    @Test
    func draftPreservesPhotoOrder() {
        let first = PhotoPDFItem(data: Data([1]), displayName: "1")
        let second = PhotoPDFItem(data: Data([2]), displayName: "2")
        let draft = PhotoPDFDraft(items: [first, second])
        #expect(draft.items.map(\.id) == [first.id, second.id])
    }
}
