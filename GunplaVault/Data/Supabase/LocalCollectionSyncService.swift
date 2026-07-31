import Foundation

/// No-op sync for free users or when Supabase is unavailable.
final class LocalCollectionSyncService: CollectionSyncService, @unchecked Sendable {
    static let shared = LocalCollectionSyncService()

    var isConfigured: Bool { false }

    private init() {}

    func fullSync(userID: String, localItems: [CollectionItem]) async throws -> [CollectionItem] {
        localItems
    }

    func pushItem(_ item: CollectionItem) async throws {}

    func deleteRemoteItem(id: UUID, userID: String) async throws {}
}
