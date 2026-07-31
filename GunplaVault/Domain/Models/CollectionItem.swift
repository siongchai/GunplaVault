import Foundation

enum SubscriptionConfig {
    static let freeKitLimit = 25
}

struct CollectionItem: Identifiable, Equatable, Codable {
    let id: UUID
    var userID: String
    var seedKitID: String?
    var name: String
    var series: String
    var grade: KitGrade
    var scale: String
    var releaseYear: Int
    var partCount: Int?
    var modelNumber: String?
    var notes: String?
    var pricePaid: Double?
    var status: CollectionStatus
    var acquiredDate: Date
    var updatedAt: Date
    var customTags: [String]
    var buildSteps: [BuildStep]
    var buildLogs: [BuildLogEntry]
    var totalBuildSeconds: TimeInterval
    var manualBook: Int
    var manualPage: Int
    var manualStep: Int
    var manualStepTotal: Int

    init(
        id: UUID = UUID(),
        userID: String,
        seedKitID: String? = nil,
        name: String,
        series: String,
        grade: KitGrade,
        scale: String,
        releaseYear: Int,
        partCount: Int? = nil,
        modelNumber: String? = nil,
        notes: String? = nil,
        pricePaid: Double? = nil,
        status: CollectionStatus = .backlog,
        acquiredDate: Date = Date(),
        updatedAt: Date = Date(),
        customTags: [String] = [],
        buildSteps: [BuildStep] = [],
        buildLogs: [BuildLogEntry] = [],
        totalBuildSeconds: TimeInterval = 0,
        manualBook: Int = 1,
        manualPage: Int = 1,
        manualStep: Int = 1,
        manualStepTotal: Int = 18
    ) {
        self.id = id
        self.userID = userID
        self.seedKitID = seedKitID
        self.name = name
        self.series = series
        self.grade = grade
        self.scale = scale
        self.releaseYear = releaseYear
        self.partCount = partCount
        self.modelNumber = modelNumber
        self.notes = notes
        self.pricePaid = pricePaid
        self.status = status
        self.acquiredDate = acquiredDate
        self.updatedAt = updatedAt
        self.customTags = customTags
        self.buildSteps = buildSteps
        self.buildLogs = buildLogs
        self.totalBuildSeconds = totalBuildSeconds
        self.manualBook = manualBook
        self.manualPage = manualPage
        self.manualStep = manualStep
        self.manualStepTotal = manualStepTotal
    }

    static func from(seedKit: SeedKit, userID: String) -> CollectionItem {
        CollectionItem(
            userID: userID,
            seedKitID: seedKit.id,
            name: seedKit.name,
            series: seedKit.series,
            grade: seedKit.grade,
            scale: seedKit.scale,
            releaseYear: seedKit.releaseYear,
            partCount: seedKit.partCount,
            modelNumber: seedKit.modelNumber,
            customTags: seedKit.tags
        )
    }
}

struct CollectionStats: Equatable {
    let totalKits: Int
    let inProgress: Int
    let completed: Int
    let backlog: Int
    let totalValuePaid: Double

    static let empty = CollectionStats(totalKits: 0, inProgress: 0, completed: 0, backlog: 0, totalValuePaid: 0)
}

enum CollectionSort: String, CaseIterable, Identifiable {
    case recent
    case name
    case grade

    var id: String { rawValue }

    var label: String {
        switch self {
        case .recent: return "Recent"
        case .name: return "Name"
        case .grade: return "Grade"
        }
    }
}

enum CollectionError: LocalizedError {
    case freeLimitReached
    case notFound

    var errorDescription: String? {
        switch self {
        case .freeLimitReached:
            return "Free plan is limited to \(SubscriptionConfig.freeKitLimit) kits. Upgrade to Pro for unlimited collection."
        case .notFound:
            return "Kit not found in your collection."
        }
    }
}

struct ActivityEntry: Identifiable, Equatable {
    let id: UUID
    let title: String
    let subtitle: String
    let date: Date
    let status: CollectionStatus
}
