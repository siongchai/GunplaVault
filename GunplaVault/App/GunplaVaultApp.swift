import SwiftUI

@main
struct GunplaVaultApp: App {
    @StateObject private var appState = AppState.makeDefault()
    @StateObject private var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.colorScheme)
        }
    }
}
