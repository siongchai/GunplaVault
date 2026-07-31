import Foundation
import SwiftUI

@MainActor
final class BuildStore: ObservableObject {
    @Published private(set) var activeItemID: UUID?
    @Published private(set) var sessionElapsed: TimeInterval = 0
    @Published private(set) var isTimerRunning = false
    @Published var showPaywall = false
    @Published var errorMessage: String?

    private weak var collectionStore: CollectionStore?
    private weak var profileStore: ProfileStore?
    private var sessionStartedAt: Date?
    private var timerTask: Task<Void, Never>?

    var activeItem: CollectionItem? {
        guard let activeItemID, let collectionStore else { return nil }
        return collectionStore.item(id: activeItemID)
    }

    var inProgressItems: [CollectionItem] {
        collectionStore?.items.filter { $0.status == .inProgress } ?? []
    }

    var isPro: Bool {
        profileStore?.tier == .pro
    }

    func bind(collectionStore: CollectionStore, profileStore: ProfileStore) {
        self.collectionStore = collectionStore
        self.profileStore = profileStore
    }

    // MARK: - Build lifecycle

    func startBuild(for item: CollectionItem) throws {
        guard var updated = collectionStore?.item(id: item.id) else { throw BuildError.notFound }

        if isPro {
            if updated.buildSteps.isEmpty {
                updated.buildSteps = BuildStepTemplate.makeDefaultSteps()
            }
            updated.status = .inProgress
            updated.updatedAt = Date()
            try collectionStore?.update(updated)
            activeItemID = updated.id
            resetSessionTimer()
        } else {
            updated.status = .inProgress
            updated.updatedAt = Date()
            try collectionStore?.update(updated)
        }
    }

    func completeBuild(for item: CollectionItem) throws {
        guard isPro else { throw BuildError.proRequired }
        guard var updated = collectionStore?.item(id: item.id) else { throw BuildError.notFound }

        pauseTimer(saveElapsed: true)
        updated.status = .completed
        updated.buildSteps = updated.buildSteps.map { step in
            var s = step
            s.isCompleted = true
            return s
        }
        updated.updatedAt = Date()
        try collectionStore?.update(updated)

        if activeItemID == item.id {
            activeItemID = nil
            sessionElapsed = 0
        }
        syncHoursBuilt()
    }

    func setActiveBuild(_ item: CollectionItem) {
        guard item.status == .inProgress else { return }
        activeItemID = item.id
        resetSessionTimer()
    }

    // MARK: - Steps

    func toggleStep(_ step: BuildStep, for item: CollectionItem) throws {
        guard isPro else { showPaywall = true; throw BuildError.proRequired }
        guard var updated = collectionStore?.item(id: item.id) else { throw BuildError.notFound }
        guard let index = updated.buildSteps.firstIndex(where: { $0.id == step.id }) else { return }

        updated.buildSteps[index].isCompleted.toggle()
        updated.updatedAt = Date()
        try collectionStore?.update(updated)
    }

    func finishCurrentStep(for item: CollectionItem, notes: String? = nil) throws {
        guard isPro else { showPaywall = true; throw BuildError.proRequired }
        guard var updated = collectionStore?.item(id: item.id) else { throw BuildError.notFound }

        if let index = updated.buildSteps.firstIndex(where: { !$0.isCompleted }) {
            updated.buildSteps[index].isCompleted = true
            let stepTitle = updated.buildSteps[index].title
            let log = BuildLogEntry(
                stepTitle: stepTitle,
                book: updated.manualBook,
                page: updated.manualPage,
                step: updated.manualStep,
                notes: notes
            )
            updated.buildLogs.insert(log, at: 0)

            if updated.manualStep < updated.manualStepTotal {
                updated.manualStep += 1
            }
        }

        updated.updatedAt = Date()
        try collectionStore?.update(updated)
    }

    func updateManualReference(for item: CollectionItem, book: Int, page: Int, step: Int, stepTotal: Int) throws {
        guard isPro else { throw BuildError.proRequired }
        guard var updated = collectionStore?.item(id: item.id) else { throw BuildError.notFound }
        updated.manualBook = book
        updated.manualPage = page
        updated.manualStep = step
        updated.manualStepTotal = stepTotal
        updated.updatedAt = Date()
        try collectionStore?.update(updated)
    }

    func addPhoto(_ image: UIImage, for item: CollectionItem, notes: String? = nil) throws {
        guard isPro else { showPaywall = true; throw BuildError.proRequired }
        guard var updated = collectionStore?.item(id: item.id) else { throw BuildError.notFound }

        let filename = try BuildPhotoStorage.save(image: image)
        let log = BuildLogEntry(
            stepTitle: updated.currentStepTitle,
            book: updated.manualBook,
            page: updated.manualPage,
            step: updated.manualStep,
            notes: notes,
            photoFilename: filename
        )
        updated.buildLogs.insert(log, at: 0)
        updated.updatedAt = Date()
        try collectionStore?.update(updated)
    }

    func addJournalNote(for item: CollectionItem, notes: String) throws {
        guard isPro else { throw BuildError.proRequired }
        guard var updated = collectionStore?.item(id: item.id) else { throw BuildError.notFound }
        let log = BuildLogEntry(stepTitle: updated.currentStepTitle, notes: notes)
        updated.buildLogs.insert(log, at: 0)
        updated.updatedAt = Date()
        try collectionStore?.update(updated)
    }

    // MARK: - Timer

    func toggleTimer(for item: CollectionItem) {
        guard isPro else { showPaywall = true; return }
        if isTimerRunning {
            pauseTimer(saveElapsed: true)
        } else {
            startTimer(for: item)
        }
    }

    func startTimer(for item: CollectionItem) {
        guard isPro else { showPaywall = true; return }
        activeItemID = item.id
        sessionStartedAt = Date()
        isTimerRunning = true
        timerTask?.cancel()
        timerTask = Task {
            while !Task.isCancelled && isTimerRunning {
                try? await Task.sleep(for: .seconds(1))
                if let sessionStartedAt {
                    sessionElapsed = Date().timeIntervalSince(sessionStartedAt)
                }
            }
        }
    }

    func pauseTimer(saveElapsed: Bool) {
        timerTask?.cancel()
        timerTask = nil
        if saveElapsed, var item = activeItem, sessionElapsed > 0 {
            item.totalBuildSeconds += sessionElapsed
            item.updatedAt = Date()
            try? collectionStore?.update(item)
            syncHoursBuilt()
        }
        isTimerRunning = false
        sessionStartedAt = nil
        sessionElapsed = 0
    }

    private func resetSessionTimer() {
        pauseTimer(saveElapsed: false)
    }

    private func syncHoursBuilt() {
        guard let collectionStore, let profileStore else { return }
        let totalSeconds = collectionStore.items.reduce(0) { $0 + $1.totalBuildSeconds }
        profileStore.syncHoursBuilt(totalSeconds / 3600)
    }

    func formattedSessionTime(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func formattedTotalTime(for item: CollectionItem) -> String {
        let total = item.totalBuildSeconds + (activeItemID == item.id && isTimerRunning ? sessionElapsed : 0)
        return formattedSessionTime(total)
    }
}
