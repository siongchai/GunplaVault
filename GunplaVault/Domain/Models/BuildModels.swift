import Foundation

struct BuildStep: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var sortOrder: Int

    init(id: UUID = UUID(), title: String, isCompleted: Bool = false, sortOrder: Int) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.sortOrder = sortOrder
    }
}

struct BuildLogEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var stepTitle: String?
    var book: Int?
    var page: Int?
    var step: Int?
    var notes: String?
    var photoFilename: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        stepTitle: String? = nil,
        book: Int? = nil,
        page: Int? = nil,
        step: Int? = nil,
        notes: String? = nil,
        photoFilename: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.stepTitle = stepTitle
        self.book = book
        self.page = page
        self.step = step
        self.notes = notes
        self.photoFilename = photoFilename
        self.createdAt = createdAt
    }
}

enum BuildStepTemplate {
    static let defaultSteps = [
        "Head Unit",
        "Torso",
        "Arms",
        "Legs",
        "Backpack",
        "Weapons",
        "Panel Lining",
        "Decals",
        "Final Assembly"
    ]

    static func makeDefaultSteps() -> [BuildStep] {
        defaultSteps.enumerated().map { index, title in
            BuildStep(title: title, sortOrder: index)
        }
    }
}

extension CollectionItem {
    var buildProgress: Double {
        guard !buildSteps.isEmpty else { return status == .completed ? 1 : 0 }
        let completed = buildSteps.filter(\.isCompleted).count
        return Double(completed) / Double(buildSteps.count)
    }

    var buildProgressPercent: Int {
        Int((buildProgress * 100).rounded())
    }

    var hasBuildTracking: Bool {
        !buildSteps.isEmpty || !buildLogs.isEmpty || totalBuildSeconds > 0
    }

    var totalBuildHours: Double {
        totalBuildSeconds / 3600
    }

    var currentStepTitle: String? {
        buildSteps.first(where: { !$0.isCompleted })?.title
    }

    var manualStepLabel: String {
        "Book \(manualBook), Page \(manualPage), Step \(manualStep)/\(manualStepTotal)"
    }
}
