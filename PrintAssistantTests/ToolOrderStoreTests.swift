import Foundation
import Testing
@testable import PrintAssistant

struct ToolOrderStoreTests {
    @Test
    func defaultsReturnEveryToolInCatalogOrder() {
        let store = ToolOrderStore(defaults: makeDefaults())

        #expect(store.load() == ToolCatalog.defaultOrder)
    }

    @Test
    func loadRemovesUnknownDuplicateAndWrongGroupIDsAndAppendsMissingTools() throws {
        let defaults = makeDefaults()
        let payload: [String: Any] = [
            "version": 1,
            "groups": [
                ToolGroup.documents.rawValue: [
                    ToolID.ocr.rawValue,
                    ToolID.ocr.rawValue,
                    "unknown-tool",
                    ToolID.idTools.rawValue
                ],
                ToolGroup.printAndID.rawValue: [ToolID.pdfTools.rawValue]
            ]
        ]
        defaults.set(try JSONSerialization.data(withJSONObject: payload), forKey: ToolOrderStore.storageKey)

        let order = ToolOrderStore(defaults: defaults).load()

        #expect(order[.documents] == [
            .ocr,
            .pdfTools,
            .batchProcessing,
            .compressPDF,
            .protectPDF,
            .unlockPDF
        ])
        #expect(order[.printAndID] == [
            .idTools,
            .photoPDF,
            .photoID,
            .printTemplates
        ])
        #expect(order[.morePDF] == [.mergePDF, .splitPDF])
    }

    @Test
    func corruptOrUnsupportedPayloadFallsBackToDefaults() throws {
        let defaults = makeDefaults()
        let store = ToolOrderStore(defaults: defaults)

        defaults.set(Data("not-json".utf8), forKey: ToolOrderStore.storageKey)
        #expect(store.load() == ToolCatalog.defaultOrder)

        let unsupported: [String: Any] = [
            "version": 999,
            "groups": [ToolGroup.documents.rawValue: [ToolID.ocr.rawValue]]
        ]
        defaults.set(try JSONSerialization.data(withJSONObject: unsupported), forKey: ToolOrderStore.storageKey)
        #expect(store.load() == ToolCatalog.defaultOrder)
    }

    @Test
    func saveAndLoadRoundTripPreservesNormalizedOrder() {
        let store = ToolOrderStore(defaults: makeDefaults())
        var order = ToolCatalog.defaultOrder
        order[.documents]?.swapAt(0, 1)

        store.save(order)

        #expect(store.load() == order)
    }

    private func makeDefaults() -> UserDefaults {
        let suite = "tool-order-(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }
}
