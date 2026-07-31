import SwiftUI

enum MainTab: String, CaseIterable, Identifiable {
    case home
    case collection
    case build
    case explore
    case profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .collection: return "Collection"
        case .build: return "Build"
        case .explore: return "Explore"
        case .profile: return "Profile"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .collection: return "square.grid.2x2.fill"
        case .build: return "hammer.fill"
        case .explore: return "safari.fill"
        case .profile: return "person.fill"
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab: MainTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label(MainTab.home.title, systemImage: MainTab.home.icon) }
                .tag(MainTab.home)
                .accessibilityLabel("Home tab")

            CollectionView()
                .tabItem { Label(MainTab.collection.title, systemImage: MainTab.collection.icon) }
                .tag(MainTab.collection)

            BuildView()
                .tabItem { Label(MainTab.build.title, systemImage: MainTab.build.icon) }
                .tag(MainTab.build)

            ExploreComingSoonView()
                .tabItem { Label(MainTab.explore.title, systemImage: MainTab.explore.icon) }
                .tag(MainTab.explore)

            ProfileView()
                .tabItem { Label(MainTab.profile.title, systemImage: MainTab.profile.icon) }
                .tag(MainTab.profile)
        }
        .tint(GVColors.accent)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState.makeDefault(authService: MockAuthService.shared))
        .environmentObject(ThemeManager())
        .environmentObject(ProfileStore())
        .environmentObject(CollectionStore(context: PersistenceController.shared.mainContext, profileStore: ProfileStore()))
}
