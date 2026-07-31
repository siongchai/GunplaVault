import Foundation

@MainActor
final class ProfileStore: ObservableObject {
    @Published private(set) var profile: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service: ProfileService
    private var userID: String?

    init(service: ProfileService = ProfileServiceFactory.current) {
        self.service = service
    }

    var tier: SubscriptionTier {
        profile?.tier ?? .free
    }

    func configure(userID: String) {
        self.userID = userID
    }

    func load() async {
        guard let userID else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            profile = try await service.fetchProfile(userID: userID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createIfNeeded(displayName: String, email: String) async {
        guard let userID else { return }
        isLoading = true
        defer { isLoading = false }

        if let existing = try? await service.fetchProfile(userID: userID) {
            profile = existing
            return
        }

        let newProfile = UserProfile(
            id: userID,
            displayName: displayName,
            email: email,
            avatarURL: nil,
            tier: .free,
            builderSince: Date(),
            kitCount: 0,
            completedCount: 0,
            hoursBuilt: 0
        )

        do {
            try await service.upsertProfile(newProfile)
            profile = newProfile
        } catch {
            // Fall back to local-only profile when Supabase table isn't ready.
            profile = newProfile
            try? await LocalProfileService.shared.upsertProfile(newProfile)
        }
    }

    func updateDisplayName(_ name: String) async {
        guard var current = profile else { return }
        current.displayName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        profile = current
        try? await service.upsertProfile(current)
    }

    func syncStats(kitCount: Int, completedCount: Int) {
        guard var current = profile else { return }
        current.kitCount = kitCount
        current.completedCount = completedCount
        profile = current
    }

    func syncHoursBuilt(_ hours: Double) {
        guard var current = profile else { return }
        current.hoursBuilt = hours
        profile = current
    }

    func setTier(_ tier: SubscriptionTier) async {
        guard var current = profile else { return }
        guard current.tier != tier else { return }
        current.tier = tier
        profile = current
        do {
            try await service.upsertProfile(current)
        } catch {
            try? await LocalProfileService.shared.upsertProfile(current)
        }
    }

    func clear() {
        profile = nil
        userID = nil
    }
}
