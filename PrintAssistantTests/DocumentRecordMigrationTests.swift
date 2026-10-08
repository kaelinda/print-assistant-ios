import Foundation
import Testing
@testable import PrintAssistant

struct DocumentRecordMigrationTests {
    @Test
    func decodesIndexCreatedBeforeSearchableTextExisted() throws {
        let record = DocumentRecord(
            name: "legacy.pdf",
            pageCount: 1,
            byteCount: 100,
            source: .scan,
            localURL: URL(fileURLWithPath: "/tmp/legacy.pdf")
        )

        let encoded = try JSONEncoder().encode(record)
        var object = try #require(
            JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        )
        object.removeValue(forKey: "searchableText")

        let legacyData = try JSONSerialization.data(withJSONObject: object)
        let decoded = try JSONDecoder().decode(DocumentRecord.self, from: legacyData)

        #expect(decoded.id == record.id)
        #expect(decoded.name == "legacy.pdf")
        #expect(decoded.searchableText == nil)
    }
}
