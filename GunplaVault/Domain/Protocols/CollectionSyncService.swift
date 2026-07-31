import Foundation

protocol CollectionSyncService: Sendable {
    var isConfigured: Bool { get }
    func fullSync(userID: String, localItems: [CollectionItem]) async throws -> [CollectionItem]
    func pushItem(_ item: CollectionItem) async throws
    func deleteRemoteItem(id: UUID, userID: String) async throws
}

enum CollectionSyncError: LocalizedError {
    case notConfigured
    case notPro
    case network(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Cloud sync requires Supabase configuration."
        case .notPro:
            return "Cloud sync is a Pro feature."
        case .network(let message):
            return message
        }
    }
}
