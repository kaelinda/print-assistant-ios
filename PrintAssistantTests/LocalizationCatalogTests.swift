import Foundation
import Testing

struct LocalizationCatalogTests {
    @Test
    func localizableCatalogTranslatesEveryKey() throws {
        let catalog = try loadCatalog("Localizable.xcstrings")
        #expect(catalog["sourceLanguage"] as? String == "zh-Hans")
        let strings = try #require(catalog["strings"] as? [String: Any])
        #expect(!strings.isEmpty)
        for (_, value) in strings {
            let entry = try #require(value as? [String: Any])
            for language in ["zh-Hans", "en"] {
                #expect(translatedValue(entry, language: language) != nil)
            }
        }
        #expect(plain("1 寸", in: strings, language: "en") == "1 in")
        #expect(plain("2 寸", in: strings, language: "en") == "2 in")
        #expect(plain("文本", in: strings, language: "en") == "Text")
        #expect(plain("信纸", in: strings, language: "en") == "US Letter")
        #expect(plain("证件", in: strings, language: "en") == "ID")
        #expect(plain("badge.document", in: strings, language: "zh-Hans") == "文档")
        #expect(plain("badge.document", in: strings, language: "en") == "Doc")
        let pages = try #require(strings["%lld 页"] as? [String: Any])
        let english = try #require((pages["localizations"] as? [String: Any])?["en"] as? [String: Any])
        let plural = try #require((english["variations"] as? [String: Any])?["plural"] as? [String: Any])
        #expect(plural["one"] != nil)
        #expect(plural["other"] != nil)
    }

    @Test
    func infoPlistCatalogCoversDisplayNameAndPermissions() throws {
        let catalog = try loadCatalog("InfoPlist.xcstrings")
        #expect(catalog["sourceLanguage"] as? String == "zh-Hans")
        let strings = try #require(catalog["strings"] as? [String: Any])
        let keys = [
            "CFBundleDisplayName",
            "NSCameraUsageDescription",
            "NSPhotoLibraryUsageDescription",
            "NSPhotoLibraryAddUsageDescription"
        ]
        for key in keys {
            let entry = try #require(strings[key] as? [String: Any])
            #expect(translatedValue(entry, language: "zh-Hans") != nil)
            #expect(translatedValue(entry, language: "en") != nil)
        }
        #expect(plain("CFBundleDisplayName", in: strings, language: "en") == "Print Assistant")
        #expect(plain("CFBundleDisplayName", in: strings, language: "zh-Hans") == "打印助手")
    }

    private func loadCatalog(_ name: String) throws -> [String: Any] {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("PrintAssistant")
            .appendingPathComponent(name)
        let data = try Data(contentsOf: url)
        return try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    private func translatedValue(_ entry: [String: Any], language: String) -> String? {
        guard
            let localizations = entry["localizations"] as? [String: Any],
            let languageEntry = localizations[language] as? [String: Any]
        else { return nil }
        if let unit = languageEntry["stringUnit"] as? [String: Any],
           let value = unit["value"] as? String,
           !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return value
        }
        guard
            let variations = languageEntry["variations"] as? [String: Any],
            let plural = variations["plural"] as? [String: Any],
            let one = (plural["one"] as? [String: Any])?["stringUnit"] as? [String: Any],
            let other = (plural["other"] as? [String: Any])?["stringUnit"] as? [String: Any],
            let oneValue = one["value"] as? String,
            let otherValue = other["value"] as? String,
            !oneValue.isEmpty,
            !otherValue.isEmpty
        else { return nil }
        return otherValue
    }

    private func plain(_ key: String, in strings: [String: Any], language: String) -> String? {
        guard let entry = strings[key] as? [String: Any] else { return nil }
        return translatedValue(entry, language: language)
    }
}
