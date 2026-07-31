import Foundation
import SwiftData

final class SwiftDataCollectionRepository: CollectionRepository, @unchecked Sendable {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll(userID: String) throws -> [CollectionItem] {
        let uid = userID
        var descriptor = FetchDescriptor<CollectionItemRecord>(
            predicate: #Predicate { $0.userID == uid },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try context.fetch(descriptor).map { $0.toDomain() }
    }

    func save(_ item: CollectionItem) throws {
        let itemID = item.id
        var descriptor = FetchDescriptor<CollectionItemRecord>(
            predicate: #Predicate { $0.id == itemID }
        )
        if let existing = try context.fetch(descriptor).first {
            existing.apply(item)
        } else {
            context.insert(CollectionItemRecord(from: item))
        }
        try context.save()
    }

    func delete(id: UUID, userID: String) throws {
        let itemID = id
        let uid = userID
        var descriptor = FetchDescriptor<CollectionItemRecord>(
            predicate: #Predicate { $0.id == itemID && $0.userID == uid }
        )
        if let existing = try context.fetch(descriptor).first {
            context.delete(existing)
            try context.save()
        }
    }

    func count(userID: String) throws -> Int {
        let uid = userID
        var descriptor = FetchDescriptor<CollectionItemRecord>(
            predicate: #Predicate { $0.userID == uid }
        )
        return try context.fetchCount(descriptor)
    }
}
