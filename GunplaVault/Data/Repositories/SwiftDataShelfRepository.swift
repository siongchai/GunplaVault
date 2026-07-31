import Foundation
import SwiftData

final class SwiftDataShelfRepository: @unchecked Sendable {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll(userID: String) throws -> [VirtualShelf] {
        let uid = userID
        var descriptor = FetchDescriptor<VirtualShelfRecord>(
            predicate: #Predicate { $0.userID == uid },
            sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try context.fetch(descriptor).map { $0.toDomain() }
    }

    func save(_ shelf: VirtualShelf) throws {
        let shelfID = shelf.id
        var descriptor = FetchDescriptor<VirtualShelfRecord>(
            predicate: #Predicate { $0.id == shelfID }
        )
        if let existing = try context.fetch(descriptor).first {
            existing.apply(shelf)
        } else {
            context.insert(VirtualShelfRecord(from: shelf))
        }
        try context.save()
    }

    func delete(id: UUID, userID: String) throws {
        let shelfID = id
        let uid = userID
        var descriptor = FetchDescriptor<VirtualShelfRecord>(
            predicate: #Predicate { $0.id == shelfID && $0.userID == uid }
        )
        if let existing = try context.fetch(descriptor).first {
            context.delete(existing)
            try context.save()
        }
    }
}
