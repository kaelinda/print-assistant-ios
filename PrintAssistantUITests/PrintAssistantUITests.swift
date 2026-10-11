import XCTest

final class PrintAssistantUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testMainTabsRenderAndNavigate() throws {
        let app = XCUIApplication()
        app.launch()

        for (identifier, title) in [
            ("tab-recent", "最近"),
            ("tab-files", "文件"),
            ("tab-search", "搜索"),
            ("tab-tools", "工具")
        ] {
            let tabButton = app.buttons[identifier]
            XCTAssertTrue(tabButton.waitForExistence(timeout: 15), "Missing tab: \(identifier)")
            tabButton.tap()
            assertSelected(tabButton, "Tab not selected: \(identifier)")
            XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 10), "Missing screen title: \(title)")
            attachScreenshot(of: app, named: identifier)
        }
    }

    func testPDFToolEntryScreensRender() throws {
        let app = XCUIApplication()
        for title in ["合并 PDF", "拆分 PDF", "页面管理", "压缩 PDF", "加密 PDF", "解除 PDF 密码"] {
            if app.state != .notRunning { app.terminate() }
            app.launch()

            let tools = app.buttons["tab-tools"]
            XCTAssertTrue(tools.waitForExistence(timeout: 15))
            tools.tap()
            assertSelected(tools, "Tools tab not selected")

            let tool = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", title)).firstMatch
            for _ in 0..<6 {
                if tool.exists && tool.isHittable { break }
                app.swipeUp()
            }
            XCTAssertTrue(tool.waitForExistence(timeout: 5) && tool.isHittable, "Missing tool: \(title)")
            tool.tap()
            XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 10), "Failed to open: \(title)")
            attachScreenshot(of: app, named: "PDF-tool-\(title)")
        }
    }

    func testPhotoOCRAndIDCopyEntryScreensRender() throws {
        let app = XCUIApplication()
        for (toolTitle, navigationTitle) in [
            ("图片转 PDF", "选择图片"),
            ("文字识别", "文字识别"),
            ("身份证复印", "人像面")
        ] {
            if app.state != .notRunning { app.terminate() }
            app.launch()

            let tools = app.buttons["tab-tools"]
            XCTAssertTrue(tools.waitForExistence(timeout: 15))
            tools.tap()
            assertSelected(tools, "Tools tab not selected")

            let entry = app.buttons.matching(
                NSPredicate(format: "label CONTAINS %@", toolTitle)
            ).firstMatch
            for _ in 0..<6 {
                if entry.exists && entry.isHittable { break }
                app.swipeUp()
            }
            XCTAssertTrue(
                entry.waitForExistence(timeout: 5) && entry.isHittable,
                "Missing tool: \(toolTitle)"
            )
            entry.tap()
            XCTAssertTrue(
                app.navigationBars[navigationTitle].waitForExistence(timeout: 10),
                "Failed to open: \(toolTitle)"
            )
            attachScreenshot(of: app, named: "extra-tool-\(toolTitle)")
        }
    }

    private func assertSelected(_ element: XCUIElement, _ message: String) {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "isSelected == true"),
            object: element
        )
        XCTAssertEqual(XCTWaiter().wait(for: [expectation], timeout: 5), .completed, message)
    }

    private func attachScreenshot(of app: XCUIApplication, named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
