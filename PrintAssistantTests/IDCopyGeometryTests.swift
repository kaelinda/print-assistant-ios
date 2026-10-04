import Foundation
import Testing
@testable import PrintAssistant

struct IDCopyGeometryTests {
    @Test
    func id1CardUsesPhysicalStandardDimensions() {
        let size = PhysicalPrintGeometry.id1CardSize
        let widthMM = size.width / 72 * 25.4
        let heightMM = size.height / 72 * 25.4

        #expect(abs(widthMM - 85.60) < 0.01)
        #expect(abs(heightMM - 53.98) < 0.01)
    }

    @Test
    func completedDraftRequiresBothSides() {
        var draft = IDCopyDraft()
        #expect(!draft.isComplete)

        draft.frontData = Data([1])
        #expect(!draft.isComplete)

        draft.backData = Data([2])
        #expect(draft.isComplete)
    }
}
