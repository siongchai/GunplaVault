import Foundation

struct VirtualShelf: Identifiable, Equatable, Codable {
    let id: UUID
    var userID: String
    var name: String
    var photoFilenames: [String]
    var sortOrder: Int
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        userID: String,
        name: String,
        photoFilenames: [String] = [],
        sortOrder: Int = 0,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userID = userID
        self.name = name
        self.photoFilenames = photoFilenames
        self.sortOrder = sortOrder
        self.updatedAt = updatedAt
    }
}

enum ShelfConfig {
    static let freeShelfLimit = 1
}

enum ShelfError: LocalizedError {
    case limitReached
    case notFound

    var errorDescription: String? {
        switch self {
        case .limitReached:
            return "Free plan includes 1 virtual shelf. Upgrade to Pro for unlimited shelves."
        case .notFound:
            return "Shelf not found."
        }
    }
}
