import Foundation
import SwiftData

@MainActor
final class AppState: ObservableObject {
    @Published var authSession: AuthSession?
    @Published var isLoading = true
    @Published private(set) var profileStore: ProfileStore
    @Published private(set) var collectionStore: CollectionStore
    @Published private(set) var subscriptionStore: SubscriptionStore
    @Published private(set) var buildStore: BuildStore
    @Published private(set) var shelfStore: ShelfStore

    var isAuthenticated: Bool {
        authSession != nil
    }

    private let authService: AuthService
    private let modelContext: ModelContext

    init(
        authService: AuthService = AuthServiceFactory.current,
        modelContext: ModelContext
    ) {
        self.authService = authService
        self.modelContext = modelContext
        let profile = ProfileStore()
        let subscription = SubscriptionStore()
        self.profileStore = profile
        self.subscriptionStore = subscription
        self.collectionStore = CollectionStore(context: modelContext, profileStore: profile)
        self.buildStore = BuildStore()
        self.shelfStore = ShelfStore(context: modelContext, profileStore: profile)
        subscription.bind(profileStore: profile)
        buildStore.bind(collectionStore: collectionStore, profileStore: profile)
    }

    @MainActor
    static func makeDefault(authService: AuthService = AuthServiceFactory.current) -> AppState {
        AppState(
            authService: authService,
            modelContext: PersistenceController.shared.mainContext
        )
    }

    func bootstrap() async {
        defer { isLoading = false }
        guard let session = await authService.restoreSession() else { return }
        await activateSession(session)
        await profileStore.load()
        await subscriptionStore.bootstrap()
        await collectionStore.load()
        shelfStore.load()
    }

    func finishOnboarding(session: AuthSession, displayName: String) async {
        authSession = session
        await activateSession(session)
        await profileStore.createIfNeeded(displayName: displayName, email: session.email)
        await subscriptionStore.bootstrap()
        await collectionStore.load()
        shelfStore.load()
    }

    func signIn(session: AuthSession) {
        authSession = session
        Task {
            await activateSession(session)
            await profileStore.load()
            await subscriptionStore.bootstrap()
            await collectionStore.load()
            shelfStore.load()
        }
    }

    func signOut() async {
        await authService.signOut()
        authSession = nil
        profileStore.clear()
        collectionStore.configure(userID: "")
        shelfStore.clear()
        await collectionStore.load()
    }

    func onProActivated() async {
        await subscriptionStore.refresh()
        await collectionStore.load()
    }

    private func activateSession(_ session: AuthSession) async {
        profileStore.configure(userID: session.userID)
        collectionStore.configure(userID: session.userID)
        shelfStore.configure(userID: session.userID)
    }
}
