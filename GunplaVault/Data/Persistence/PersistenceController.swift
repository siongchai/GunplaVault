import Foundation
import SwiftData

// MARK: - Versioned schemas (additive migrations)

enum GunplaSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [CollectionItemRecord.self]
    }
}

enum GunplaSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [CollectionItemRecord.self]
    }
}

enum GunplaSchemaV3: VersionedSchema {
    static var versionIdentifier = Schema.Version(3, 0, 0)

    static var models: [any PersistentModel.Type] {
        [CollectionItemRecord.self, VirtualShelfRecord.self]
    }
}

enum GunplaVaultMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [GunplaSchemaV1.self, GunplaSchemaV2.self, GunplaSchemaV3.self]
    }

    static var stages: [MigrationStage] {
        [
            MigrationStage.lightweight(fromVersion: GunplaSchemaV1.self, toVersion: GunplaSchemaV2.self),
            MigrationStage.lightweight(fromVersion: GunplaSchemaV2.self, toVersion: GunplaSchemaV3.self)
        ]
    }
}

// MARK: - Container

enum PersistenceController {
    private static let storeFilename = "GunplaVault.store"

    static let shared: ModelContainer = {
        createContainer(resetIfNeeded: false)
    }()

    @MainActor
    static var mainContext: ModelContext {
        shared.mainContext
    }

    private static var storeURL: URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return directory.appendingPathComponent(storeFilename)
    }

    private static func createContainer(resetIfNeeded: Bool) -> ModelContainer {
        let schema = Schema(versionedSchema: GunplaSchemaV3.self)
        let configuration = ModelConfiguration(schema: schema, url: storeURL)

        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: GunplaVaultMigrationPlan.self,
                configurations: [configuration]
            )
        } catch {
            guard !resetIfNeeded else {
                fatalError("Failed to create ModelContainer after reset: \(error)")
            }

            #if DEBUG
            print("SwiftData migration failed, resetting local store: \(error)")
            #endif

            deleteStoreFiles()
            return createContainer(resetIfNeeded: true)
        }
    }

    private static func deleteStoreFiles() {
        let urls = [
            storeURL,
            storeURL.appendingPathExtension("shm"),
            storeURL.appendingPathExtension("wal")
        ]
        for url in urls {
            try? FileManager.default.removeItem(at: url)
        }

        // Remove legacy default store from earlier builds without a custom URL.
        if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            for name in ["default.store", "default.store-shm", "default.store-wal"] {
                try? FileManager.default.removeItem(at: appSupport.appendingPathComponent(name))
            }
        }
    }
}
