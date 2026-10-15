import CoreGraphics
import Foundation
import PDFKit
import Testing
import UIKit
@testable import PrintAssistant

struct PhotoIDGeometryTests {
    @Test
    func oneInchIs25By35MillimetersOnA2By3Grid() {
        let spec = PhotoIDGeometry.spec(for: "1 寸")
        #expect(spec.widthMillimeters == 25)
        #expect(spec.heightMillimeters == 35)
        #expect(spec.columns == 2)
        #expect(spec.rows == 3)
        #expect(spec.sheetCount == 6)

        let widthMM = spec.cardSize.width / 72 * 25.4
        let heightMM = spec.cardSize.height / 72 * 25.4
        #expect(abs(widthMM - 25) < 0.01)
        #expect(abs(heightMM - 35) < 0.01)
    }

    @Test
    func twoInchIs35By49MillimetersOnA2By2Grid() {
        let spec = PhotoIDGeometry.spec(for: "2寸")
        #expect(spec.widthMillimeters == 35)
        #expect(spec.heightMillimeters == 49)
        #expect(spec.columns == 2)
        #expect(spec.rows == 2)
        #expect(spec.sheetCount == 4)
    }

    @Test
    func unknownSizeFallsBackToOneInch() {
        #expect(PhotoIDGeometry.spec(for: "大头贴") == PhotoIDGeometry.oneInch)
    }

    @Test
    func cropRectMatchesAspectAndClampsOffset() {
        let image = CGSize(width: 200, height: 100)
        let aspect = CGSize(width: 25, height: 35)
        let centered = PhotoIDGeometry.cropRect(imageSize: image, aspect: aspect, offset: .zero)
        let targetAspect = aspect.width / aspect.height

        #expect(abs(centered.width / centered.height - targetAspect) < 0.001)
        #expect(abs(centered.midX - image.width / 2) < 0.001)
        #expect(abs(centered.midY - image.height / 2) < 0.001)

        let leading = PhotoIDGeometry.cropRect(
            imageSize: image,
            aspect: aspect,
            offset: CGSize(width: -2, height: 4)
        )
        #expect(abs(leading.minX) < 0.001)
        #expect(leading.maxX <= image.width + 0.001)
        #expect(leading.maxY <= image.height + 0.001)

        let trailing = PhotoIDGeometry.cropRect(
            imageSize: image,
            aspect: aspect,
            offset: CGSize(width: 1, height: 0)
        )
        #expect(abs(trailing.maxX - image.width) < 0.001)
    }

    @Test
    func portraitImageCropsHeightToTheCardAspect() {
        let image = CGSize(width: 100, height: 200)
        let aspect = PhotoIDGeometry.twoInch.cardSize
        let crop = PhotoIDGeometry.cropRect(imageSize: image, aspect: aspect, offset: .zero)
        #expect(abs(crop.width - 100) < 0.001)
        #expect(crop.height < image.height)
        #expect(abs(crop.width / crop.height - aspect.width / aspect.height) < 0.001)
    }

    @Test
    func emptyImageProducesAnEmptyCrop() {
        let crop = PhotoIDGeometry.cropRect(imageSize: .zero, aspect: CGSize(width: 25, height: 35), offset: .zero)
        #expect(crop == .zero)
    }

    @Test
    func photoIDLayoutUsesTheSelectedSizeInsteadOfAlwaysUsingOneInchSixUp() {
        let oneInch = PhotoIDGeometry.cardRects(for: PhotoIDGeometry.spec(for: "1 寸"))
        let twoInch = PhotoIDGeometry.cardRects(for: PhotoIDGeometry.spec(for: "2 寸"))

        #expect(oneInch.count == 6)
        #expect(twoInch.count == 4)
        #expect(twoInch[0].width > oneInch[0].width)
        #expect(twoInch[0].height > oneInch[0].height)
    }
}
