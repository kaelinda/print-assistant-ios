import SwiftUI

@main
struct PrintAssistantApp: App {
    @State private var appModel = AppModel()

    init() {
        if ProcessInfo.processInfo.arguments.contains("-UITestResetToolOrder") {
            UserDefaults.standard.removeObject(forKey: ToolOrderStore.storageKey)
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(appModel)
                .tint(DesignTokens.Color.accent)
                .preferredColorScheme(screenshotColorScheme)
        }
    }

    /// Screenshot runs pass these arguments. A normal launch follows the system appearance.
    private var screenshotColorScheme: ColorScheme? {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("ScreenshotAppearanceDark") {
            return .dark
        }
        if arguments.contains("ScreenshotAppearanceLight") {
            return .light
        }
        return nil
    }
}
