import SwiftUI

struct KitDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var collectionStore: CollectionStore
    @EnvironmentObject private var buildStore: BuildStore
    @EnvironmentObject private var profileStore: ProfileStore

    @State private var selectedTab: DetailTab = .overview
    @State private var priceText: String
    @State private var notes: String
    @State private var showDeleteConfirm = false
    @State private var showCompleteConfirm = false

    let itemID: UUID

    init(item: CollectionItem) {
        itemID = item.id
        _priceText = State(initialValue: item.pricePaid.map { String(format: "%.2f", $0) } ?? "")
        _notes = State(initialValue: item.notes ?? "")
    }

    private var item: CollectionItem? {
        collectionStore.item(id: itemID)
    }

    var body: some View {
        Group {
            if let item {
                detailContent(item)
            } else {
                ContentUnavailableView("Kit Not Found", systemImage: "shippingbox")
            }
        }
        .background(GVColors.background)
        .navigationTitle("Kit Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $collectionStore.showPaywall) {
            PaywallView().environmentObject(appState)
        }
        .confirmationDialog("Remove this kit?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Remove", role: .destructive) {
                if let item { try? collectionStore.delete(item); dismiss() }
            }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Mark as completed?", isPresented: $showCompleteConfirm, titleVisibility: .visible) {
            Button("Complete") {
                if let item { markCompleted(item) }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    @ViewBuilder
    private func detailContent(_ item: CollectionItem) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    heroSection(item)
                    tabPicker
                    tabContent(item)
                }
                .padding(20)
            }

            actionBar(item)
        }
        .onChange(of: item.id) { _, _ in
            priceText = item.pricePaid.map { String(format: "%.2f", $0) } ?? ""
            notes = item.notes ?? ""
        }
    }

    private func heroSection(_ item: CollectionItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            BoxArtImage(urlString: item.boxArtURL, cornerRadius: 16)
                .frame(height: 220)
                .frame(maxWidth: .infinity)

            HStack {
                GVCapsuleBadge(text: item.grade.rawValue)
                StatusBadge(status: item.status)
                if buildStore.isPro && item.status == .inProgress {
                    GVCapsuleBadge(text: "\(item.buildProgressPercent)%", tint: GVColors.accent)
                }
            }

            Text(item.name)
                .font(GVTypography.title)
                .foregroundStyle(GVColors.textPrimary)
            Text(item.series)
                .font(GVTypography.callout)
                .foregroundStyle(GVColors.textSecondary)

            HStack(spacing: 12) {
                SpecTile(label: "Scale", value: item.scale)
                SpecTile(label: "Year", value: String(item.releaseYear))
                if let parts = item.partCount {
                    SpecTile(label: "Parts", value: String(parts))
                }
            }
        }
    }

    private var tabPicker: some View {
        Picker("Tab", selection: $selectedTab) {
            ForEach(DetailTab.allCases) { tab in
                Text(tab.title).tag(tab)
            }
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    private func tabContent(_ item: CollectionItem) -> some View {
        switch selectedTab {
        case .overview:
            overviewTab(item)
        case .buildLog:
            buildLogTab(item)
        case .photos:
            photosTab(item)
        case .notes:
            notesTab(item)
        }
    }

    private func overviewTab(_ item: CollectionItem) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            GVCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Status")
                        .font(GVTypography.headline)
                    Picker("Status", selection: statusBinding(item)) {
                        ForEach(CollectionStatus.allCases, id: \.self) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }

            GVCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Details")
                        .font(GVTypography.headline)
                    GVTextField(title: "Price paid", text: $priceText, keyboardType: .decimalPad)
                    GVPrimaryButton(title: "Save") { saveOverview(item) }
                }
            }

            if buildStore.isPro && item.hasBuildTracking {
                GVCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Build Stats")
                            .font(GVTypography.headline)
                        Label("Total time: \(buildStore.formattedTotalTime(for: item))", systemImage: "timer")
                        Label("\(item.buildLogs.count) journal entries", systemImage: "note.text")
                        Label("\(item.buildSteps.filter(\.isCompleted).count)/\(item.buildSteps.count) steps", systemImage: "checkmark.circle")
                    }
                    .font(GVTypography.callout)
                    .foregroundStyle(GVColors.textSecondary)
                }
            }

            Button(role: .destructive) { showDeleteConfirm = true } label: {
                Text("Remove from Collection")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .background(GVColors.surface, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    @ViewBuilder
    private func buildLogTab(_ item: CollectionItem) -> some View {
        if buildStore.isPro {
            if item.buildLogs.isEmpty {
                emptyProTab(message: "No build log entries yet. Start Build Mode to journal your progress.")
            } else {
                VStack(spacing: 12) {
                    ForEach(item.buildLogs) { log in
                        BuildLogRow(log: log)
                            .padding(12)
                            .background(GVColors.surface, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        } else {
            proLockedTab
        }
    }

    @ViewBuilder
    private func photosTab(_ item: CollectionItem) -> some View {
        if buildStore.isPro {
            let photos = item.buildLogs.compactMap(\.photoFilename)
            if photos.isEmpty {
                emptyProTab(message: "No build photos yet. Add photos from Build Mode.")
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(photos, id: \.self) { filename in
                        if let image = BuildPhotoStorage.load(filename: filename) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
            }
        } else {
            proLockedTab
        }
    }

    private func notesTab(_ item: CollectionItem) -> some View {
        GVCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Notes")
                    .font(GVTypography.headline)
                GVTextField(title: "Your notes", text: $notes)
                GVPrimaryButton(title: "Save Notes") { saveOverview(item) }
            }
        }
    }

    private var proLockedTab: some View {
        GVCard {
            VStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .foregroundStyle(GVColors.accent)
                Text("Pro feature")
                    .font(GVTypography.headline)
                Text("Upgrade to Pro for build logs, photos, and full Build Mode.")
                    .font(GVTypography.callout)
                    .foregroundStyle(GVColors.textSecondary)
                    .multilineTextAlignment(.center)
                Button("View Pro") { collectionStore.showPaywall = true }
                    .foregroundStyle(GVColors.accent)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }

    private func emptyProTab(message: String) -> some View {
        GVCard {
            Text(message)
                .font(GVTypography.callout)
                .foregroundStyle(GVColors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }

    private func actionBar(_ item: CollectionItem) -> some View {
        VStack(spacing: 0) {
            Divider()
            VStack(spacing: 10) {
                switch item.status {
                case .backlog, .completed:
                    GVPrimaryButton(title: startBuildTitle) { startBuild(item) }
                case .inProgress:
                    if buildStore.isPro {
                        NavigationLink {
                            BuildSessionView(itemID: item.id)
                        } label: {
                            Text("Continue Build")
                                .font(GVTypography.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .foregroundStyle(.white)
                                .background(GVColors.accent, in: RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    Button("Mark Completed") { showCompleteConfirm = true }
                        .font(GVTypography.callout)
                        .foregroundStyle(GVColors.accent)
                }
            }
            .padding(16)
            .background(GVColors.background)
        }
    }

    private var startBuildTitle: String {
        buildStore.isPro ? "Start Build" : "Start Building (Status Only)"
    }

    private func statusBinding(_ item: CollectionItem) -> Binding<CollectionStatus> {
        Binding(
            get: { collectionStore.item(id: item.id)?.status ?? item.status },
            set: { newStatus in
                guard var updated = collectionStore.item(id: item.id) else { return }
                updated.status = newStatus
                try? collectionStore.update(updated)
            }
        )
    }

    private func saveOverview(_ item: CollectionItem) {
        guard var updated = collectionStore.item(id: item.id) else { return }
        updated.pricePaid = Double(priceText.trimmingCharacters(in: .whitespacesAndNewlines))
        updated.notes = notes.isEmpty ? nil : notes
        try? collectionStore.update(updated)
    }

    private func startBuild(_ item: CollectionItem) {
        do {
            try buildStore.startBuild(for: item)
        } catch BuildError.proRequired {
            collectionStore.showPaywall = true
        } catch {
            collectionStore.errorMessage = error.localizedDescription
        }
    }

    private func markCompleted(_ item: CollectionItem) {
        if buildStore.isPro {
            try? buildStore.completeBuild(for: item)
        } else {
            guard var updated = collectionStore.item(id: item.id) else { return }
            updated.status = .completed
            try? collectionStore.update(updated)
        }
    }
}

private enum DetailTab: String, CaseIterable, Identifiable {
    case overview
    case buildLog
    case photos
    case notes

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: return "Overview"
        case .buildLog: return "Build Log"
        case .photos: return "Photos"
        case .notes: return "Notes"
        }
    }
}

private struct SpecTile: View {
    let label: String
    let value: String

    var body: some View {
        GVCard {
            VStack(spacing: 4) {
                Text(value)
                    .font(GVTypography.headline)
                Text(label)
                    .font(GVTypography.caption)
                    .foregroundStyle(GVColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    NavigationStack {
        KitDetailView(item: CollectionItem(
            userID: "demo",
            name: "Strike Freedom Gundam",
            series: "Gundam SEED DESTINY",
            grade: .mg,
            scale: "1/100",
            releaseYear: 2006,
            status: .inProgress,
            buildSteps: BuildStepTemplate.makeDefaultSteps()
        ))
    }
    .environmentObject(AppState.makeDefault())
    .environmentObject(CollectionStore(context: PersistenceController.shared.mainContext, profileStore: ProfileStore()))
    .environmentObject(BuildStore())
    .environmentObject(ProfileStore())
}
