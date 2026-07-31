import Foundation

struct GradeSlice: Identifiable, Equatable {
    let grade: KitGrade
    let count: Int

    var id: String { grade.rawValue }

    var label: String { grade.rawValue }
}

struct TimelineBar: Identifiable, Equatable {
    let year: Int
    let count: Int

    var id: Int { year }
}

struct AnalyticsSnapshot: Equatable {
    let totalKits: Int
    let completedKits: Int
    let inProgressKits: Int
    let backlogKits: Int
    let completionRate: Double
    let totalSpent: Double
    let averagePrice: Double
    let gradeBreakdown: [GradeSlice]
    let timeline: [TimelineBar]
    let kitsAddedThisYear: Int
    let hoursBuilt: Double

    static let empty = AnalyticsSnapshot(
        totalKits: 0, completedKits: 0, inProgressKits: 0, backlogKits: 0,
        completionRate: 0, totalSpent: 0, averagePrice: 0,
        gradeBreakdown: [], timeline: [], kitsAddedThisYear: 0, hoursBuilt: 0
    )
}

enum AnalyticsCalculator {
    static func compute(items: [CollectionItem], hoursBuilt: Double) -> AnalyticsSnapshot {
        guard !items.isEmpty else {
            return AnalyticsSnapshot(
                totalKits: 0, completedKits: 0, inProgressKits: 0, backlogKits: 0,
                completionRate: 0, totalSpent: 0, averagePrice: 0,
                gradeBreakdown: [], timeline: [], kitsAddedThisYear: 0, hoursBuilt: hoursBuilt
            )
        }

        let completed = items.filter { $0.status == .completed }.count
        let inProgress = items.filter { $0.status == .inProgress }.count
        let backlog = items.filter { $0.status == .backlog }.count
        let prices = items.compactMap(\.pricePaid)
        let totalSpent = prices.reduce(0, +)
        let average = prices.isEmpty ? 0 : totalSpent / Double(prices.count)

        var gradeCounts: [KitGrade: Int] = [:]
        for item in items {
            gradeCounts[item.grade, default: 0] += 1
        }
        let gradeBreakdown = gradeCounts
            .map { GradeSlice(grade: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }

        var yearCounts: [Int: Int] = [:]
        for item in items {
            let year = Calendar.current.component(.year, from: item.acquiredDate)
            yearCounts[year, default: 0] += 1
        }
        let timeline = yearCounts.keys.sorted().map { TimelineBar(year: $0, count: yearCounts[$0] ?? 0) }

        let currentYear = Calendar.current.component(.year, from: Date())
        let kitsThisYear = items.filter {
            Calendar.current.component(.year, from: $0.acquiredDate) == currentYear
        }.count

        return AnalyticsSnapshot(
            totalKits: items.count,
            completedKits: completed,
            inProgressKits: inProgress,
            backlogKits: backlog,
            completionRate: Double(completed) / Double(items.count),
            totalSpent: totalSpent,
            averagePrice: average,
            gradeBreakdown: gradeBreakdown,
            timeline: timeline,
            kitsAddedThisYear: kitsThisYear,
            hoursBuilt: hoursBuilt
        )
    }
}
