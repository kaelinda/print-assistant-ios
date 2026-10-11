import CoreGraphics
import Foundation
import Testing
@testable import PrintAssistant

struct PrintTemplateTests {
    @Test
    func defaultsUseA4AndOneCopy() {
        let template = PrintTemplate(
            name: "合同打印",
            subtitle: "A4 · 100% · 12 mm 边距",
            category: .document
        )
        let layout = PrintLayout(template: template)
        #expect(layout.paperSize == PrintLayout.a4)
        #expect(layout.scale == .fit(1))
        #expect(layout.copies == 1)
        #expect(abs(layout.marginPoints - PrintLayout.points(millimeters: 12)) < 0.01)
    }

    @Test
    func roundTripPreservesPrintFields() throws {
        let template = PrintTemplate(
            name: "身份证复印",
            subtitle: "A4 · 实际尺寸",
            category: .id,
            paper: "A5",
            scale: "实际尺寸",
            marginMillimeters: 8,
            copies: 3
        )
        let data = try JSONEncoder().encode(template)
        let decoded = try JSONDecoder().decode(PrintTemplate.self, from: data)
        #expect(decoded == template)

        let layout = PrintLayout(template: decoded)
        #expect(layout.paperSize == PrintLayout.a5)
        #expect(layout.scale == .actualSize)
        #expect(layout.copies == 3)
    }

    @Test
    func fitScaleStaysInsideMarginsAndCopiesAreClamped() {
        let rect = PrintLayout.destinationRect(
            pageSize: CGSize(width: 100, height: 100),
            paperSize: CGSize(width: 200, height: 400),
            marginPoints: 10,
            scale: .fit(1)
        )
        #expect(abs(rect.width - 180) < 0.01)
        #expect(abs(rect.height - 180) < 0.01)
        #expect(abs(rect.midX - 100) < 0.01)
        #expect(rect.minX >= 10)
        #expect(rect.maxX <= 190)

        let half = PrintLayout.destinationRect(
            pageSize: CGSize(width: 100, height: 100),
            paperSize: CGSize(width: 200, height: 400),
            marginPoints: 10,
            scale: .fit(0.5)
        )
        #expect(abs(half.width - 90) < 0.01)

        #expect(PrintLayout.normalizedCopies(0) == 1)
        #expect(PrintLayout.normalizedCopies(120) == 99)
        #expect(PrintLayout.paperSize(named: "Letter") == PrintLayout.letter)
    }
}
