import Foundation

protocol CollectionRepository: Sendable {
    func fetchAll(userID: String) throws -> [CollectionItem]
    func save(_ item: CollectionItem) throws
    func delete(id: UUID, userID: String) throws
    func count(userID: String) throws -> Int
}

protocol ProfileService: Sendable {
    func fetchProfile(userID: String) async throws -> UserProfile?
    func upsertProfile(_ profile: UserProfile) async throws
    func deleteProfile(userID: String) async throws
}

enum ProfileError: LocalizedError {
    case notConfigured
    case notFound
    case network(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Profile sync requires Supabase configuration."
        case .notFound:
            return "Profile not found."
        case .network(let message):
            return message
        }
    }
}
