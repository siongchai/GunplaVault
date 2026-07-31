import SwiftUI
import Charts

struct AnalyticsView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var collectionStore: CollectionStore
    @EnvironmentObject private var profileStore: ProfileStore
    @EnvironmentObject private var shelfStore: ShelfStore

    @State private var selectedTab: AnalyticsTab = .overview
    @State private var exportURL: URL?
    @State private var showExportSheet = false
    @State private var showPaywall = false

    private var isPro: Bool { profileStore.tier == .pro }

    private var snapshot: AnalyticsSnapshot {
        AnalyticsCalculator.compute(
            items: collectionStore.items,
            hoursBuilt: profileStore.profile?.hoursBuilt ?? 0
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ScreenHeader(
                    title: "Insights",
                    subtitle: isPro ? "Analytics for your collection" : "Upgrade to Pro for full analytics"
                )

                if !isPro {
                    proBanner
                }

                Picker("Tab", selection: $selectedTab) {
                    ForEach(AnalyticsTab.allCases) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)

                switch selectedTab {
                case .overview:
                    overviewTab
                case .collection:
                    collectionTab
                case .spending:
                    spendingTab
                }

                if isPro {
                    exportSection
                }
            }
            .padding(20)
        }
        .background(GVColors.background)
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) {
            PaywallView().environmentObject(appState)
        }
        .sheet(isPresented: $showExportSheet) {
            if let exportURL {
                ShareSheet(items: [exportURL])
            }
        }
    }

    private var proBanner: some View {
        GVCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Pro Analytics")
                    .font(GVTypography.headline)
                    .foregroundStyle(GVColors.accent)
                Text("Charts, spending breakdown, and CSV/PDF export require Pro.")
                    .font(GVTypography.callout)
                    .foregroundStyle(GVColors.textSecondary)
                Button("Upgrade to Pro") { showPaywall = true }
                    .font(GVTypography.callout)
                    .foregroundStyle(GVColors.accent)
            }
        }
    }

    private var overviewTab: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                SummaryTile(title: "Total Kits", value: "\(snapshot.totalKits)")
                SummaryTile(title: "Completion", value: "\(Int(snapshot.completionRate * 100))%")
                SummaryTile(title: "This Year", value: "\(snapshot.kitsAddedThisYear)")
            }

            if isPro {
                GVCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Collection by Grade")
                            .font(GVTypography.headline)
                        if snapshot.gradeBreakdown.isEmpty {
                            emptyChartPlaceholder
                        } else {
                            Chart(snapshot.gradeBreakdown) { slice in
                                SectorMark(
                                    angle: .value("Count", slice.count),
                                    innerRadius: .ratio(0.55),
                                    angularInset: 1.5
                                )
                                .foregroundStyle(by: .value("Grade", slice.label))
                            }
                            .frame(height: 220)
                            .chartLegend(position: .bottom, spacing: 8)

                            ForEach(snapshot.gradeBreakdown) { slice in
                                HStack {
                                    Text(slice.label)
                                        .font(GVTypography.callout)
                                    Spacer()
                                    Text("\(slice.count)")
                                        .font(GVTypography.headline)
                                }
                            }
                        }
                    }
                }
            } else {
                lockedChartCard(title: "Collection by Grade")
            }
        }
    }

    private var collectionTab: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                SummaryTile(title: "Backlog", value: "\(snapshot.backlogKits)")
                SummaryTile(title: "Building", value: "\(snapshot.inProgressKits)")
                SummaryTile(title: "Completed", value: "\(snapshot.completedKits)")
            }

            if isPro {
                GVCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Collection Timeline")
                            .font(GVTypography.headline)
                        if snapshot.timeline.isEmpty {
                            emptyChartPlaceholder
                        } else {
                            Chart(snapshot.timeline) { bar in
                                BarMark(
                                    x: .value("Year", String(bar.year)),
                                    y: .value("Kits", bar.count)
                                )
                                .foregroundStyle(GVColors.accent.gradient)
                            }
                            .frame(height: 200)
                        }
                    }
                }
            } else {
                lockedChartCard(title: "Collection Timeline")
            }
        }
    }

    private var spendingTab: some View {
        VStack(spacing: 16) {
            GVCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Spending Summary")
                        .font(GVTypography.headline)
                    LabeledRow(label: "Total spent", value: formatCurrency(snapshot.totalSpent))
                    LabeledRow(label: "Average per kit", value: formatCurrency(snapshot.averagePrice))
                    LabeledRow(label: "Kits with price", value: "\(collectionStore.items.filter { $0.pricePaid != nil }.count)")
                }
            }

            if !isPro {
                lockedChartCard(title: "Spending trends — Pro")
            }
        }
    }

    private var exportSection: some View {
        GVCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Export")
                    .font(GVTypography.headline)
                Text("Download your collection as CSV or a summary PDF report.")
                    .font(GVTypography.callout)
                    .foregroundStyle(GVColors.textSecondary)

                HStack(spacing: 12) {
                    Button("Export CSV") { exportCSV() }
                        .buttonStyle(ExportButtonStyle())
                    Button("Export PDF") { exportPDF() }
                        .buttonStyle(ExportButtonStyle())
                }
            }
        }
    }

    private var emptyChartPlaceholder: some View {
        Text("Add kits to see charts.")
            .font(GVTypography.callout)
            .foregroundStyle(GVColors.textSecondary)
            .frame(maxWidth: .infinity, minHeight: 80)
    }

    private func lockedChartCard(title: String) -> some View {
        GVCard {
            VStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .foregroundStyle(GVColors.textSecondary)
                Text(title)
                    .font(GVTypography.headline)
                Text("Available with Pro")
                    .font(GVTypography.caption)
                    .foregroundStyle(GVColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        }
    }

    private func exportCSV() {
        let csv = CollectionExporter.csv(items: collectionStore.items)
        exportURL = try? CollectionExporter.writeCSVToTempFile(csv)
        showExportSheet = exportURL != nil
    }

    private func exportPDF() {
        exportURL = try? CollectionExporter.pdf(
            items: collectionStore.items,
            profile: profileStore.profile,
            snapshot: snapshot
        )
        showExportSheet = exportURL != nil
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

private enum AnalyticsTab: String, CaseIterable, Identifiable {
    case overview, collection, spending

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: return "Overview"
        case .collection: return "Collection"
        case .spending: return "Spending"
        }
    }
}

private struct SummaryTile: View {
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

private struct LabeledRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(GVTypography.callout)
                .foregroundStyle(GVColors.textSecondary)
            Spacer()
            Text(value)
                .font(GVTypography.headline)
        }
    }
}

private struct ExportButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(GVTypography.callout)
            .foregroundStyle(GVColors.accent)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(GVColors.surfaceSecondary, in: Capsule())
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        AnalyticsView()
    }
    .environmentObject(AppState.makeDefault())
    .environmentObject(ShelfStore(context: PersistenceController.shared.mainContext, profileStore: ProfileStore()))
}
