import Foundation
import SwiftData

@Model
final class CollectionItemRecord {
    @Attribute(.unique) var id: UUID
    var userID: String
    var seedKitID: String?
    var name: String
    var series: String
    var gradeRaw: String
    var scale: String
    var releaseYear: Int
    var partCount: Int?
    var modelNumber: String?
    var boxArtURL: String?
    var notes: String?
    var pricePaid: Double?
    var statusRaw: String
    var acquiredDate: Date
    var updatedAt: Date
    var customTags: [String]
    var buildStepsData: Data?
    var buildLogsData: Data?
    var totalBuildSeconds: Double = 0
    var manualBook: Int = 1
    var manualPage: Int = 1
    var manualStep: Int = 1
    var manualStepTotal: Int = 18

    init() {
        id = UUID()
        userID = ""
        name = ""
        series = ""
        gradeRaw = KitGrade.other.rawValue
        scale = ""
        releaseYear = 0
        statusRaw = CollectionStatus.backlog.rawValue
        acquiredDate = Date()
        updatedAt = Date()
        customTags = []
    }

    init(from item: CollectionItem) {
        id = item.id
        userID = item.userID
        seedKitID = item.seedKitID
        name = item.name
        series = item.series
        gradeRaw = item.grade.rawValue
        scale = item.scale
        releaseYear = item.releaseYear
        partCount = item.partCount
        modelNumber = item.modelNumber
        boxArtURL = item.boxArtURL
        notes = item.notes
        pricePaid = item.pricePaid
        statusRaw = item.status.rawValue
        acquiredDate = item.acquiredDate
        updatedAt = item.updatedAt
        customTags = item.customTags
        buildStepsData = Self.encode(item.buildSteps)
        buildLogsData = Self.encode(item.buildLogs)
        totalBuildSeconds = item.totalBuildSeconds
        manualBook = item.manualBook
        manualPage = item.manualPage
        manualStep = item.manualStep
        manualStepTotal = item.manualStepTotal
    }

    func apply(_ item: CollectionItem) {
        seedKitID = item.seedKitID
        name = item.name
        series = item.series
        gradeRaw = item.grade.rawValue
        scale = item.scale
        releaseYear = item.releaseYear
        partCount = item.partCount
        modelNumber = item.modelNumber
        boxArtURL = item.boxArtURL
        notes = item.notes
        pricePaid = item.pricePaid
        statusRaw = item.status.rawValue
        acquiredDate = item.acquiredDate
        updatedAt = item.updatedAt
        customTags = item.customTags
        buildStepsData = Self.encode(item.buildSteps)
        buildLogsData = Self.encode(item.buildLogs)
        totalBuildSeconds = item.totalBuildSeconds
        manualBook = item.manualBook
        manualPage = item.manualPage
        manualStep = item.manualStep
        manualStepTotal = item.manualStepTotal
    }

    func toDomain() -> CollectionItem {
        CollectionItem(
            id: id,
            userID: userID,
            seedKitID: seedKitID,
            name: name,
            series: series,
            grade: KitGrade(rawValue: gradeRaw) ?? .other,
            scale: scale,
            releaseYear: releaseYear,
            partCount: partCount,
            modelNumber: modelNumber,
            boxArtURL: boxArtURL,
            notes: notes,
            pricePaid: pricePaid,
            status: CollectionStatus(rawValue: statusRaw) ?? .backlog,
            acquiredDate: acquiredDate,
            updatedAt: updatedAt,
            customTags: customTags,
            buildSteps: Self.decode([BuildStep].self, from: buildStepsData) ?? [],
            buildLogs: Self.decode([BuildLogEntry].self, from: buildLogsData) ?? [],
            totalBuildSeconds: totalBuildSeconds,
            manualBook: manualBook == 0 ? 1 : manualBook,
            manualPage: manualPage == 0 ? 1 : manualPage,
            manualStep: manualStep == 0 ? 1 : manualStep,
            manualStepTotal: manualStepTotal == 0 ? 18 : manualStepTotal
        )
    }

    private static func encode<T: Encodable>(_ value: T) -> Data? {
        try? JSONEncoder().encode(value)
    }

    private static func decode<T: Decodable>(_ type: T.Type, from data: Data?) -> T? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
