import Foundation
import SwiftData

@MainActor
final class CollectionStore: ObservableObject {
    @Published private(set) var items: [CollectionItem] = []
    @Published private(set) var stats = CollectionStats.empty
    @Published private(set) var recentActivity: [ActivityEntry] = []
    @Published private(set) var isSyncing = false
    @Published private(set) var lastSyncedAt: Date?
    @Published var searchQuery = ""
    @Published var selectedGrade: KitGrade?
    @Published var sort: CollectionSort = .recent
    @Published var errorMessage: String?
    @Published var showPaywall = false

    private let repository: CollectionRepository
    private let syncService: CollectionSyncService
    private weak var profileStore: ProfileStore?
    private var userID: String?

    init(
        context: ModelContext,
        profileStore: ProfileStore,
        syncService: CollectionSyncService = CollectionSyncServiceFactory.current
    ) {
        self.repository = SwiftDataCollectionRepository(context: context)
        self.profileStore = profileStore
        self.syncService = syncService
    }

    var filteredItems: [CollectionItem] {
        var result = items

        if let selectedGrade {
            result = result.filter { $0.grade == selectedGrade }
        }

        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !query.isEmpty {
            result = result.filter {
                [$0.name, $0.series, $0.grade.rawValue, $0.modelNumber ?? ""]
                    .joined(separator: " ")
                    .lowercased()
                    .contains(query)
            }
        }

        switch sort {
        case .recent:
            result.sort { $0.updatedAt > $1.updatedAt }
        case .name:
            result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .grade:
            result.sort { $0.grade.rawValue < $1.grade.rawValue }
        }

        return result
    }

    var canAddKit: Bool {
        guard let profileStore else { return true }
        if profileStore.tier == .pro { return true }
        return items.count < SubscriptionConfig.freeKitLimit
    }

    var remainingFreeSlots: Int {
        max(0, SubscriptionConfig.freeKitLimit - items.count)
    }

    var isCloudSyncEnabled: Bool {
        profileStore?.tier == .pro && syncService.isConfigured
    }

    func configure(userID: String) {
        self.userID = userID
    }

    func load() async {
        guard let userID else { return }
        do {
            items = try repository.fetchAll(userID: userID)

            if profileStore?.tier == .pro && syncService.isConfigured {
                isSyncing = true
                defer { isSyncing = false }
                let merged = try await syncService.fullSync(userID: userID, localItems: items)
                for item in merged {
                    try repository.save(item)
                }
                items = merged
                lastSyncedAt = Date()
            }

            refreshStats()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func syncNow() async {
        await load()
    }

    func addFromSeed(_ seedKit: SeedKit) throws {
        guard let userID else { return }
        guard canAddKit else {
            showPaywall = true
            throw CollectionError.freeLimitReached
        }

        if items.contains(where: { $0.seedKitID == seedKit.id }) {
            return
        }

        let item = CollectionItem.from(seedKit: seedKit, userID: userID)
        try repository.save(item)
        items.insert(item, at: 0)
        refreshStats()
        pushToCloud(item)
    }

    func addManual(
        name: String,
        series: String,
        grade: KitGrade,
        scale: String,
        releaseYear: Int,
        pricePaid: Double?,
        notes: String?
    ) throws {
        guard let userID else { return }
        guard canAddKit else {
            showPaywall = true
            throw CollectionError.freeLimitReached
        }

        let item = CollectionItem(
            userID: userID,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            series: series.trimmingCharacters(in: .whitespacesAndNewlines),
            grade: grade,
            scale: scale,
            releaseYear: releaseYear,
            notes: notes,
            pricePaid: pricePaid
        )
        try repository.save(item)
        items.insert(item, at: 0)
        refreshStats()
        pushToCloud(item)
    }

    func update(_ item: CollectionItem) throws {
        var updated = item
        updated.updatedAt = Date()
        try repository.save(updated)
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = updated
        }
        refreshStats()
        pushToCloud(updated)
    }

    func delete(_ item: CollectionItem) throws {
        guard let userID else { return }
        try repository.delete(id: item.id, userID: userID)
        items.removeAll { $0.id == item.id }
        refreshStats()
        deleteFromCloud(id: item.id, userID: userID)
    }

    func item(id: UUID) -> CollectionItem? {
        items.first { $0.id == id }
    }

    private func pushToCloud(_ item: CollectionItem) {
        guard isCloudSyncEnabled else { return }
        Task {
            do {
                try await syncService.pushItem(item)
                lastSyncedAt = Date()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func deleteFromCloud(id: UUID, userID: String) {
        guard isCloudSyncEnabled else { return }
        Task {
            try? await syncService.deleteRemoteItem(id: id, userID: userID)
            lastSyncedAt = Date()
        }
    }

    private func refreshStats() {
        let inProgress = items.filter { $0.status == .inProgress }.count
        let completed = items.filter { $0.status == .completed }.count
        let backlog = items.filter { $0.status == .backlog }.count
        let value = items.compactMap(\.pricePaid).reduce(0, +)

        stats = CollectionStats(
            totalKits: items.count,
            inProgress: inProgress,
            completed: completed,
            backlog: backlog,
            totalValuePaid: value
        )

        recentActivity = items
            .sorted { $0.updatedAt > $1.updatedAt }
            .prefix(5)
            .map { item in
                ActivityEntry(
                    id: item.id,
                    title: item.name,
                    subtitle: item.status.displayName,
                    date: item.updatedAt,
                    status: item.status
                )
            }

        profileStore?.syncStats(kitCount: items.count, completedCount: completed)
        profileStore?.syncHoursBuilt(items.reduce(0) { $0 + $1.totalBuildSeconds } / 3600)
    }
}
