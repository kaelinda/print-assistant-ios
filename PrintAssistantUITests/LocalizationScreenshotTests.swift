import XCTest

/// Captures the main tabs, plus Settings, for the manual localization screenshot workflow.
/// Regular CI skips this test because it does not set SCREENSHOT_DIR.
@MainActor
final class LocalizationScreenshotTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCaptureMainScreensInChineseAndEnglish() throws {
        guard let directory = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"], !directory.isEmpty else {
            throw XCTSkip("SCREENSHOT_DIR is set by the localization screenshot workflow.")
        }
        let output = URL(fileURLWithPath: directory, isDirectory: true)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

        let passes = [
            ScreenPass(
                prefix: "zh",
                launchArguments: ["-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_Hans"],
                recent: "最近",
                files: "文件",
                tools: "工具",
                search: "搜索",
                settings: "设置"
            ),
            ScreenPass(
                prefix: "en",
                launchArguments: ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"],
                recent: "Recent",
                files: "Files",
                tools: "Tools",
                search: "Search",
                settings: "Settings"
            ),
        ]

        for pass in passes {
            XCUIDevice.shared.appearance = .light
            let app = launch(pass.launchArguments)
            captureTab("tab-recent", title: pass.recent, in: app, name: "\(pass.prefix)-recent", output: output)
            captureTab("tab-files", title: pass.files, in: app, name: "\(pass.prefix)-files", output: output)
            captureTab("tab-tools", title: pass.tools, in: app, name: "\(pass.prefix)-tools", output: output)
            captureTab("tab-search", title: pass.search, in: app, name: "\(pass.prefix)-search", output: output)
            openSettings(in: app, title: pass.settings, name: "\(pass.prefix)-settings", output: output)
            app.terminate()

            XCUIDevice.shared.appearance = .dark
            let darkApp = launch(pass.launchArguments)
            captureTab("tab-recent", title: pass.recent, in: darkApp, name: "\(pass.prefix)-recent-dark", output: output)
            captureTab("tab-tools", title: pass.tools, in: darkApp, name: "\(pass.prefix)-tools-dark", output: output)
            darkApp.terminate()
        }

        XCUIDevice.shared.appearance = .light
    }

    private struct ScreenPass {
        let prefix: String
        let launchArguments: [String]
        let recent: String
        let files: String
        let tools: String
        let search: String
        let settings: String
    }

    private func launch(_ arguments: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = arguments
        app.launch()
        return app
    }

    private func captureTab(
        _ identifier: String,
        title: String,
        in app: XCUIApplication,
        name: String,
        output: URL
    ) {
        let tab = app.buttons[identifier]
        XCTAssertTrue(tab.waitForExistence(timeout: 15), "Missing tab: \(identifier)")
        tab.tap()
        assertSelected(tab, "Tab not selected: \(identifier)")
        XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 10), "Missing screen title: \(title)")
        saveScreenshot(of: app, named: name, output: output)
    }

    private func openSettings(in app: XCUIApplication, title: String, name: String, output: URL) {
        let tools = app.buttons["tab-tools"]
        XCTAssertTrue(tools.waitForExistence(timeout: 10))
        tools.tap()
        assertSelected(tools, "Tools tab not selected")

        let settings = app.buttons["open-settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 10), "Missing settings button")
        settings.tap()
        XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 10), "Missing settings title: \(title)")
        saveScreenshot(of: app, named: name, output: output)
    }

    private func assertSelected(_ element: XCUIElement, _ message: String) {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "isSelected == true"),
            object: element
        )
        XCTAssertEqual(XCTWaiter().wait(for: [expectation], timeout: 5), .completed, message)
    }

    private func saveScreenshot(of app: XCUIApplication, named name: String, output: URL) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)

        let url = output.appendingPathComponent("\(name).png")
        do {
            try screenshot.pngRepresentation.write(to: url, options: .atomic)
        } catch {
            XCTFail("Could not write \(url.path): \(error)")
        }
    }
}
