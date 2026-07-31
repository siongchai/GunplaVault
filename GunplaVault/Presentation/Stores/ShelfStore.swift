import Foundation
import SwiftUI
import SwiftData

@MainActor
final class ShelfStore: ObservableObject {
    @Published private(set) var shelves: [VirtualShelf] = []
    @Published var showPaywall = false
    @Published var errorMessage: String?

    private let repository: SwiftDataShelfRepository
    private weak var profileStore: ProfileStore?
    private var userID: String?

    init(context: ModelContext, profileStore: ProfileStore) {
        self.repository = SwiftDataShelfRepository(context: context)
        self.profileStore = profileStore
    }

    var isPro: Bool { profileStore?.tier == .pro }

    var canAddShelf: Bool {
        isPro || shelves.count < ShelfConfig.freeShelfLimit
    }

    func configure(userID: String) {
        self.userID = userID
    }

    func load() {
        guard let userID else { return }
        do {
            shelves = try repository.fetchAll(userID: userID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addShelf(name: String) throws {
        guard let userID else { return }
        guard canAddShelf else {
            showPaywall = true
            throw ShelfError.limitReached
        }
        let shelf = VirtualShelf(userID: userID, name: name, sortOrder: shelves.count)
        try repository.save(shelf)
        shelves.append(shelf)
    }

    func addPhoto(_ image: UIImage, to shelf: VirtualShelf) throws {
        guard var updated = shelves.first(where: { $0.id == shelf.id }) else { throw ShelfError.notFound }
        let filename = try ShelfPhotoStorage.save(image: image)
        updated.photoFilenames.append(filename)
        updated.updatedAt = Date()
        try repository.save(updated)
        if let index = shelves.firstIndex(where: { $0.id == shelf.id }) {
            shelves[index] = updated
        }
    }

    func deleteShelf(_ shelf: VirtualShelf) throws {
        guard let userID else { return }
        for filename in shelf.photoFilenames {
            ShelfPhotoStorage.delete(filename: filename)
        }
        try repository.delete(id: shelf.id, userID: userID)
        shelves.removeAll { $0.id == shelf.id }
    }

    func clear() {
        shelves = []
        userID = nil
    }
}
