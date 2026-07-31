import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var profileStore: ProfileStore
    @EnvironmentObject private var collectionStore: CollectionStore
    @EnvironmentObject private var buildStore: BuildStore
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ScreenHeader(
                        title: greeting,
                        subtitle: "Your collection dashboard"
                    )

                    collectionValueCard

                    HStack(spacing: 12) {
                        MetricTile(title: "Kits", value: "\(collectionStore.stats.totalKits)")
                        MetricTile(title: "Building", value: "\(collectionStore.stats.inProgress)")
                        MetricTile(title: "Completed", value: "\(collectionStore.stats.completed)")
                    }

                    if let todayBuild = primaryInProgressBuild {
                        todaysProgressCard(todayBuild)
                    }

                    insightsCard

                    if !collectionStore.recentActivity.isEmpty {
                        recentActivitySection
                    }
                }
                .padding(20)
            }
            .background(GVColors.background)
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ProfileAvatarView(name: profileStore.profile?.displayName ?? "Builder")
                }
            }
            .navigationDestination(for: UUID.self) { itemID in
                if buildStore.isPro {
                    BuildSessionView(itemID: itemID)
                } else if let item = collectionStore.item(id: itemID) {
                    KitDetailView(item: item)
                }
            }
        }
    }

    private var collectionValueCard: some View {
        GVGradientCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Collection Value")
                            .font(GVTypography.caption)
                            .foregroundStyle(.white.opacity(0.85))
                        Text(formatCurrency(collectionStore.stats.totalValuePaid))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    collectionSparkline
                }

                if collectionStore.stats.totalKits > 0 {
                    Text("\(collectionStore.stats.totalKits) kits tracked")
                        .font(GVTypography.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
    }

    private var collectionSparkline: some View {
        let bars = sparklineValues
        return HStack(alignment: .bottom, spacing: 3) {
            ForEach(Array(bars.enumerated()), id: \.offset) { _, value in
                RoundedRectangle(cornerRadius: 2)
                    .fill(.white.opacity(0.85))
                    .frame(width: 4, height: max(4, value * 28))
            }
        }
        .frame(height: 32)
        .accessibilityHidden(true)
    }

    private var sparklineValues: [CGFloat] {
        let timeline = AnalyticsCalculator.compute(
            items: collectionStore.items,
            hoursBuilt: profileStore.profile?.hoursBuilt ?? 0
        ).timeline
        guard !timeline.isEmpty else { return [0.3, 0.5, 0.4, 0.7, 0.6, 0.9] }
        let maxCount = CGFloat(timeline.map(\.count).max() ?? 1)
        return timeline.suffix(6).map { CGFloat($0.count) / max(maxCount, 1) }
    }

    private var insightsCard: some View {
        NavigationLink {
            AnalyticsView().environmentObject(appState)
        } label: {
            GVCard {
                HStack(spacing: 14) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(themeManager.accentGradient)
                        .frame(width: 44, height: 44)
                        .overlay {
                            Image(systemName: "chart.bar.fill")
                                .foregroundStyle(.white)
                        }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Insights & Analytics")
                            .font(GVTypography.headline)
                            .foregroundStyle(GVColors.textPrimary)
                        Text(insightsSubtitle)
                            .font(GVTypography.caption)
                            .foregroundStyle(GVColors.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(GVColors.textSecondary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(GVTypography.headline)
                .foregroundStyle(GVColors.textPrimary)

            ForEach(collectionStore.recentActivity) { entry in
                HStack(spacing: 12) {
                    Circle()
                        .fill(activityTint(entry.status).opacity(0.15))
                        .frame(width: 40, height: 40)
                        .overlay {
                            Image(systemName: activityIcon(entry.status))
                                .font(.callout)
                                .foregroundStyle(activityTint(entry.status))
                        }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.title)
                            .font(GVTypography.callout)
                            .foregroundStyle(GVColors.textPrimary)
                            .lineLimit(1)
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
                .background(GVColors.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
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
            VStack(alignment: .leading, spacing: 14) {
                Text("Today's Progress")
                    .font(GVTypography.headline)

                HStack(alignment: .top, spacing: 14) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(GVColors.surfaceSecondary)
                        .frame(width: 72, height: 72)
                        .overlay {
                            Image(systemName: "hammer.fill")
                                .font(.title2)
                                .foregroundStyle(themeManager.accentColor.opacity(0.7))
                        }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.name)
                            .font(GVTypography.headline)
                            .foregroundStyle(GVColors.textPrimary)
                            .lineLimit(2)

                        if buildStore.isPro {
                            Text(item.manualStepLabel)
                                .font(GVTypography.caption)
                                .foregroundStyle(GVColors.textSecondary)

                            GVProgressBar(progress: item.buildProgress)
                                .frame(height: 8)

                            Text("\(item.buildProgressPercent)% complete")
                                .font(GVTypography.caption)
                                .foregroundStyle(themeManager.accentColor)
                        } else {
                            StatusBadge(status: item.status)
                        }
                    }
                }

                if buildStore.isPro {
                    NavigationLink(value: item.id) {
                        Text("Continue Build")
                            .font(GVTypography.callout.weight(.semibold))
                            .foregroundStyle(themeManager.accentColor)
                    }
                }
            }
        }
    }

    private func activityIcon(_ status: CollectionStatus) -> String {
        switch status {
        case .backlog: return "shippingbox.fill"
        case .inProgress: return "hammer.fill"
        case .completed: return "checkmark.seal.fill"
        }
    }

    private func activityTint(_ status: CollectionStatus) -> Color {
        switch status {
        case .backlog: return GVColors.textSecondary
        case .inProgress: return themeManager.accentColor
        case .completed: return GVColors.success
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
                    .font(GVTypography.metric)
                    .foregroundStyle(GVColors.textPrimary)
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
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
        .environmentObject(AppState.makeDefault(authService: MockAuthService.shared))
        .environmentObject(ProfileStore())
        .environmentObject(CollectionStore(context: PersistenceController.shared.mainContext, profileStore: ProfileStore()))
        .environmentObject(BuildStore())
        .environmentObject(ThemeManager())
}
