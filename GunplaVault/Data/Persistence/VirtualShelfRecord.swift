import Foundation
import SwiftData

@Model
final class VirtualShelfRecord {
    @Attribute(.unique) var id: UUID
    var userID: String
    var name: String
    var photoFilenames: [String]
    var sortOrder: Int
    var updatedAt: Date

    init(from shelf: VirtualShelf) {
        id = shelf.id
        userID = shelf.userID
        name = shelf.name
        photoFilenames = shelf.photoFilenames
        sortOrder = shelf.sortOrder
        updatedAt = shelf.updatedAt
    }

    func apply(_ shelf: VirtualShelf) {
        name = shelf.name
        photoFilenames = shelf.photoFilenames
        sortOrder = shelf.sortOrder
        updatedAt = shelf.updatedAt
    }

    func toDomain() -> VirtualShelf {
        VirtualShelf(
            id: id,
            userID: userID,
            name: name,
            photoFilenames: photoFilenames,
            sortOrder: sortOrder,
            updatedAt: updatedAt
        )
    }
}
