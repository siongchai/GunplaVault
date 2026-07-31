import Foundation
import Supabase

final class SupabaseCollectionSyncService: CollectionSyncService, @unchecked Sendable {
    static let shared = SupabaseCollectionSyncService()

    private struct CollectionRow: Codable {
        let id: String
        let user_id: String
        let seed_kit_id: String?
        let name: String
        let series: String
        let grade: String
        let scale: String
        let release_year: Int
        let part_count: Int?
        let model_number: String?
        let notes: String?
        let price_paid: Double?
        let status: String
        let acquired_date: String
        let updated_at: String
        let custom_tags: [String]
        let build_steps: [BuildStep]?
        let build_logs: [BuildLogEntry]?
        let total_build_seconds: Double?
        let manual_book: Int?
        let manual_page: Int?
        let manual_step: Int?
        let manual_step_total: Int?
    }

    private init() {}

    var isConfigured: Bool { SupabaseManager.shared.client != nil }

    private var client: SupabaseClient? { SupabaseManager.shared.client }

    func fullSync(userID: String, localItems: [CollectionItem]) async throws -> [CollectionItem] {
        guard let client else { throw CollectionSyncError.notConfigured }

        let remoteRows: [CollectionRow] = try await client
            .from("collection_items")
            .select()
            .eq("user_id", value: userID)
            .execute()
            .value

        let remoteItems = remoteRows.compactMap { mapRow($0) }
        let remoteByID = Dictionary(uniqueKeysWithValues: remoteItems.map { ($0.id, $0) })
        var merged: [CollectionItem] = []
        let localIDs = Set(localItems.map(\.id))

        for local in localItems {
            if let remote = remoteByID[local.id] {
                let winner = local.updatedAt >= remote.updatedAt ? local : remote
                merged.append(winner)
                if winner.id == local.id && local.updatedAt >= remote.updatedAt {
                    try await pushItem(local)
                }
            } else {
                merged.append(local)
                try await pushItem(local)
            }
        }

        for remote in remoteItems where !localIDs.contains(remote.id) {
            merged.append(remote)
        }

        return merged.sorted { $0.updatedAt > $1.updatedAt }
    }

    func pushItem(_ item: CollectionItem) async throws {
        guard let client else { throw CollectionSyncError.notConfigured }

        let row = mapItem(item)
        try await client
            .from("collection_items")
            .upsert(row)
            .execute()
    }

    func deleteRemoteItem(id: UUID, userID: String) async throws {
        guard let client else { throw CollectionSyncError.notConfigured }
        try await client
            .from("collection_items")
            .delete()
            .eq("id", value: id.uuidString)
            .eq("user_id", value: userID)
            .execute()
    }

    private func mapRow(_ row: CollectionRow) -> CollectionItem? {
        guard let id = UUID(uuidString: row.id) else { return nil }
        let acquired = ISO8601DateFormatter().date(from: row.acquired_date) ?? Date()
        let updated = ISO8601DateFormatter().date(from: row.updated_at) ?? Date()

        return CollectionItem(
            id: id,
            userID: row.user_id,
            seedKitID: row.seed_kit_id,
            name: row.name,
            series: row.series,
            grade: KitGrade(rawValue: row.grade) ?? .other,
            scale: row.scale,
            releaseYear: row.release_year,
            partCount: row.part_count,
            modelNumber: row.model_number,
            notes: row.notes,
            pricePaid: row.price_paid,
            status: CollectionStatus(rawValue: row.status) ?? .backlog,
            acquiredDate: acquired,
            updatedAt: updated,
            customTags: row.custom_tags,
            buildSteps: row.build_steps ?? [],
            buildLogs: row.build_logs ?? [],
            totalBuildSeconds: row.total_build_seconds ?? 0,
            manualBook: row.manual_book ?? 1,
            manualPage: row.manual_page ?? 1,
            manualStep: row.manual_step ?? 1,
            manualStepTotal: row.manual_step_total ?? 18
        )
    }

    private func mapItem(_ item: CollectionItem) -> CollectionRow {
        CollectionRow(
            id: item.id.uuidString,
            user_id: item.userID,
            seed_kit_id: item.seedKitID,
            name: item.name,
            series: item.series,
            grade: item.grade.rawValue,
            scale: item.scale,
            release_year: item.releaseYear,
            part_count: item.partCount,
            model_number: item.modelNumber,
            notes: item.notes,
            price_paid: item.pricePaid,
            status: item.status.rawValue,
            acquired_date: ISO8601DateFormatter().string(from: item.acquiredDate),
            updated_at: ISO8601DateFormatter().string(from: item.updatedAt),
            custom_tags: item.customTags,
            build_steps: item.buildSteps.isEmpty ? nil : item.buildSteps,
            build_logs: item.buildLogs.isEmpty ? nil : item.buildLogs,
            total_build_seconds: item.totalBuildSeconds,
            manual_book: item.manualBook,
            manual_page: item.manualPage,
            manual_step: item.manualStep,
            manual_step_total: item.manualStepTotal
        )
    }
}

enum CollectionSyncServiceFactory {
    static var current: CollectionSyncService {
        if SupabaseManager.shared.isConfigured {
            return SupabaseCollectionSyncService.shared
        }
        return LocalCollectionSyncService.shared
    }
}
