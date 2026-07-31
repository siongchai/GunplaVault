import Foundation

final class SeedKitCatalog: @unchecked Sendable {
    static let shared = SeedKitCatalog()

    private(set) var kits: [SeedKit] = []
    private var loaded = false

    private init() {}

    func loadIfNeeded() throws {
        guard !loaded else { return }
        kits = try SeedKitLoader.loadBundledDatabase().kits
        loaded = true
    }

    func search(query: String, grade: KitGrade?) throws -> [SeedKit] {
        try loadIfNeeded()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return kits.filter { kit in
            if let grade, kit.grade != grade { return false }
            guard !trimmed.isEmpty else { return true }
            let haystack = [kit.name, kit.series, kit.modelNumber ?? "", kit.grade.rawValue]
                .joined(separator: " ")
                .lowercased()
            return haystack.contains(trimmed)
        }
    }

    func kit(id: String) throws -> SeedKit? {
        try loadIfNeeded()
        return kits.first { $0.id == id }
    }

    var count: Int {
        (try? loadIfNeeded()) != nil ? kits.count : 0
    }
}
