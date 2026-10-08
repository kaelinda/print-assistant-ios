import XCTest

final class PrintAssistantUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testMainTabsRenderAndNavigate() throws {
        let app = XCUIApplication()
        app.launch()

        for (tab, title) in [
            ("最近", "最近"),
            ("文件", "文件"),
            ("搜索", "搜索"),
            ("工具", "工具")
        ] {
            let tabButton = app.tabBars.buttons[tab]
            XCTAssertTrue(tabButton.waitForExistence(timeout: 15), "Missing tab: \(tab)")
            tabButton.tap()
            XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 10), "Missing navigation screen: \(title)")
            attachScreenshot(of: app, named: "tab-\(tab)")
        }
    }

    func testPDFToolEntryScreensRender() throws {
        let app = XCUIApplication()
        for title in ["合并 PDF", "拆分 PDF", "页面管理"] {
            if app.state != .notRunning { app.terminate() }
            app.launch()

            let tools = app.tabBars.buttons["工具"]
            XCTAssertTrue(tools.waitForExistence(timeout: 15))
            tools.tap()

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

            let tools = app.tabBars.buttons["工具"]
            XCTAssertTrue(tools.waitForExistence(timeout: 15))
            tools.tap()

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

    private func attachScreenshot(of app: XCUIApplication, named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
