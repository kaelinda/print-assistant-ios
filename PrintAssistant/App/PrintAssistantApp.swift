import SwiftUI

@main
struct PrintAssistantApp: App {
    @State private var appModel = AppModel()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(appModel)
                .tint(DesignTokens.Color.accent)
        }
    }
}
