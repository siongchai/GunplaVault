import Foundation

final class LocalProfileService: ProfileService, @unchecked Sendable {
    static let shared = LocalProfileService()

    private let defaults = UserDefaults.standard
    private let keyPrefix = "gv.profile."

    private init() {}

    func fetchProfile(userID: String) async throws -> UserProfile? {
        guard let data = defaults.data(forKey: keyPrefix + userID) else { return nil }
        return try JSONDecoder().decode(UserProfile.self, from: data)
    }

    func upsertProfile(_ profile: UserProfile) async throws {
        let data = try JSONEncoder().encode(profile)
        defaults.set(data, forKey: keyPrefix + profile.id)
    }

    func deleteProfile(userID: String) async throws {
        defaults.removeObject(forKey: keyPrefix + userID)
    }
}
