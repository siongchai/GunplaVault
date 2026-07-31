import Foundation

enum SeedKitLoader {
    static func loadBundledDatabase() throws -> SeedDatabase {
        guard let url = Bundle.main.url(forResource: "seed_kits", withExtension: "json") else {
            throw SeedLoaderError.missingFile
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(SeedDatabase.self, from: data)
    }
}

enum SeedLoaderError: LocalizedError {
    case missingFile

    var errorDescription: String? {
        switch self {
        case .missingFile:
            return "Seed kit database file was not found in the app bundle."
        }
    }
}

#if DEBUG
extension SeedKitLoader {
    static var previewKits: [SeedKit] {
        (try? loadBundledDatabase().kits) ?? []
    }
}
#endif
