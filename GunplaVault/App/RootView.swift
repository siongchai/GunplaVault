import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState
    @State private var splashFinished = false

    private var showSplash: Bool {
        !splashFinished || appState.isLoading
    }

    var body: some View {
        Group {
            if appState.isAuthenticated {
                MainTabView()
                    .environmentObject(appState.profileStore)
                    .environmentObject(appState.collectionStore)
                    .environmentObject(appState.subscriptionStore)
                    .environmentObject(appState.buildStore)
                    .environmentObject(appState.shelfStore)
            } else {
                AuthFlowView()
            }
        }
        .task {
            await appState.bootstrap()
        }
        .overlay {
            if showSplash {
                SplashView {
                    withAnimation(.easeOut(duration: 0.25)) {
                        splashFinished = true
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.25), value: splashFinished)
    }
}

#Preview {
    RootView()
        .environmentObject(AppState.makeDefault(authService: MockAuthService.shared))
        .environmentObject(ThemeManager())
}
