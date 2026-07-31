import Foundation
import Supabase

final class SupabaseProfileService: ProfileService, @unchecked Sendable {
    static let shared = SupabaseProfileService()

    private struct ProfileRow: Codable {
        let id: String
        var display_name: String
        var email: String
        var tier: String
        var builder_since: String
        var avatar_url: String?
    }

    private init() {}

    private var client: SupabaseClient? {
        SupabaseManager.shared.client
    }

    func fetchProfile(userID: String) async throws -> UserProfile? {
        guard let client else { throw ProfileError.notConfigured }

        do {
            let row: ProfileRow = try await client
                .from("profiles")
                .select()
                .eq("id", value: userID)
                .single()
                .execute()
                .value
            return mapRow(row)
        } catch {
            return nil
        }
    }

    func upsertProfile(_ profile: UserProfile) async throws {
        guard let client else { throw ProfileError.notConfigured }

        let row = ProfileRow(
            id: profile.id,
            display_name: profile.displayName,
            email: profile.email,
            tier: profile.tier.rawValue,
            builder_since: ISO8601DateFormatter().string(from: profile.builderSince),
            avatar_url: profile.avatarURL
        )

        do {
            try await client
                .from("profiles")
                .upsert(row)
                .execute()
        } catch {
            throw ProfileError.network(error.localizedDescription)
        }
    }

    func deleteProfile(userID: String) async throws {
        guard let client else { throw ProfileError.notConfigured }
        try await client.from("profiles").delete().eq("id", value: userID).execute()
    }

    private func mapRow(_ row: ProfileRow) -> UserProfile {
        let date = ISO8601DateFormatter().date(from: row.builder_since) ?? Date()
        return UserProfile(
            id: row.id,
            displayName: row.display_name,
            email: row.email,
            avatarURL: row.avatar_url,
            tier: SubscriptionTier(rawValue: row.tier) ?? .free,
            builderSince: date,
            kitCount: 0,
            completedCount: 0,
            hoursBuilt: 0
        )
    }
}

enum ProfileServiceFactory {
    static var current: ProfileService {
        if SupabaseManager.shared.isConfigured {
            return SupabaseProfileService.shared
        }
        return LocalProfileService.shared
    }
}
