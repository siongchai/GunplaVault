import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var profileStore: ProfileStore
    @EnvironmentObject private var collectionStore: CollectionStore
    @EnvironmentObject private var buildStore: BuildStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ScreenHeader(
                        title: greeting,
                        subtitle: profileStore.profile?.email ?? "Your collection"
                    )

                    if let todayBuild = primaryInProgressBuild {
                        todaysProgressCard(todayBuild)
                    }

                    GVCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Collection Value")
                                .font(GVTypography.caption)
                                .foregroundStyle(GVColors.textSecondary)
                            Text(formatCurrency(collectionStore.stats.totalValuePaid))
                                .font(GVTypography.title)
                                .foregroundStyle(GVColors.textPrimary)
                            Text("Sum of price paid across your collection")
                                .font(GVTypography.caption)
                                .foregroundStyle(GVColors.textSecondary)
                        }
                    }

                    HStack(spacing: 12) {
                        MetricTile(title: "Kits", value: "\(collectionStore.stats.totalKits)")
                        MetricTile(title: "Building", value: "\(collectionStore.stats.inProgress)")
                        MetricTile(title: "Completed", value: "\(collectionStore.stats.completed)")
                    }

                    insightsCard

                    if !collectionStore.recentActivity.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Activity")
                                .font(GVTypography.headline)
                                .foregroundStyle(GVColors.textPrimary)

                            ForEach(collectionStore.recentActivity) { entry in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(entry.title)
                                            .font(GVTypography.callout)
                                            .foregroundStyle(GVColors.textPrimary)
                                        Text(entry.subtitle)
                                            .font(GVTypography.caption)
                                            .foregroundStyle(GVColors.textSecondary)
                                    }
                                    Spacer()
                                    Text(entry.date, style: .relative)
                                        .font(GVTypography.caption)
                                        .foregroundStyle(GVColors.textSecondary)
                                }
                                .padding(12)
                                .background(GVColors.surface, in: RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(GVColors.background)
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: UUID.self) { itemID in
                if buildStore.isPro {
                    BuildSessionView(itemID: itemID)
                } else {
                    KitDetailView(item: collectionStore.item(id: itemID) ?? CollectionItem(
                        userID: "", name: "Kit", series: "", grade: .hg, scale: "1/144", releaseYear: 2020
                    ))
                }
            }
        }
    }

    private var insightsCard: some View {
        NavigationLink {
            AnalyticsView().environmentObject(appState)
        } label: {
            GVCard {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Insights & Analytics")
                            .font(GVTypography.headline)
                            .foregroundStyle(GVColors.textPrimary)
                        Text(insightsSubtitle)
                            .font(GVTypography.caption)
                            .foregroundStyle(GVColors.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chart.bar.fill")
                        .font(.title2)
                        .foregroundStyle(GVColors.accent)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var insightsSubtitle: String {
        let snapshot = AnalyticsCalculator.compute(
            items: collectionStore.items,
            hoursBuilt: profileStore.profile?.hoursBuilt ?? 0
        )
        if profileStore.tier == .pro {
            return "\(Int(snapshot.completionRate * 100))% completion rate"
        }
        return "View collection stats · Pro for charts"
    }

    private var primaryInProgressBuild: CollectionItem? {
        if let activeID = buildStore.activeItemID,
           let active = collectionStore.item(id: activeID),
           active.status == .inProgress {
            return active
        }
        return buildStore.inProgressItems.first
    }

    private func todaysProgressCard(_ item: CollectionItem) -> some View {
        GVCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Today's Progress")
                    .font(GVTypography.headline)

                HStack(spacing: 16) {
                    if buildStore.isPro {
                        BuildProgressRing(progress: item.buildProgress, lineWidth: 8, size: 80, label: "Done")
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.name)
                            .font(GVTypography.headline)
                            .foregroundStyle(GVColors.textPrimary)
                        if buildStore.isPro {
                            Text(item.manualStepLabel)
                                .font(GVTypography.caption)
                                .foregroundStyle(GVColors.textSecondary)
                            Text("\(item.buildProgressPercent)% complete")
                                .font(GVTypography.callout)
                                .foregroundStyle(GVColors.accent)
                        } else {
                            StatusBadge(status: item.status)
                        }
                    }

                    Spacer()

                    if buildStore.isPro {
                        NavigationLink(value: item.id) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.title2)
                                .foregroundStyle(GVColors.accent)
                        }
                    }
                }
            }
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let salutation: String
        switch hour {
        case 5..<12: salutation = "Good morning"
        case 12..<17: salutation = "Good afternoon"
        default: salutation = "Good evening"
        }
        if let name = profileStore.profile?.displayName, !name.isEmpty {
            return "\(salutation), \(name)"
        }
        return salutation
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

private struct MetricTile: View {
    let title: String
    let value: String

    var body: some View {
        GVCard {
            VStack(spacing: 4) {
                Text(value)
                    .font(GVTypography.title2)
                    .foregroundStyle(GVColors.textPrimary)
                Text(title)
                    .font(GVTypography.caption)
                    .foregroundStyle(GVColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(ProfileStore())
        .environmentObject(CollectionStore(context: PersistenceController.shared.mainContext, profileStore: ProfileStore()))
        .environmentObject(BuildStore())
}
