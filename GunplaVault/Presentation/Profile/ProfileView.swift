import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var profileStore: ProfileStore
    @EnvironmentObject private var collectionStore: CollectionStore
    @EnvironmentObject private var subscriptionStore: SubscriptionStore
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var shelfStore: ShelfStore

    @State private var editingName = false
    @State private var nameDraft = ""
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    profileCard
                    statsRow
                    navigationLinks
                    achievementsCard
                    membershipCard
                    syncCard
                    demoCard
                    signOutButton
                }
                .padding(20)
            }
            .background(GVColors.background)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showPaywall) {
                PaywallView().environmentObject(appState)
            }
            .sheet(isPresented: $collectionStore.showPaywall) {
                PaywallView().environmentObject(appState)
            }
            .alert("Edit Display Name", isPresented: $editingName) {
                TextField("Name", text: $nameDraft)
                Button("Save") {
                    Task { await profileStore.updateDisplayName(nameDraft) }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private var profileCard: some View {
        GVCard {
            HStack(spacing: 16) {
                ProfileAvatarView(
                    name: profileStore.profile?.displayName ?? "Builder",
                    size: 64
                )

                VStack(alignment: .leading, spacing: 6) {
                    Text(profileStore.profile?.displayName ?? "Builder")
                        .font(GVTypography.headline)
                    GVCapsuleBadge(
                        text: profileStore.tier.displayName,
                        tint: profileStore.tier == .pro ? themeManager.accentColor : GVColors.textSecondary
                    )
                    if let email = profileStore.profile?.email {
                        Text(email)
                            .font(GVTypography.caption)
                            .foregroundStyle(GVColors.textSecondary)
                    }
                }

                Spacer()

                Button("Edit") {
                    nameDraft = profileStore.profile?.displayName ?? ""
                    editingName = true
                }
                .font(GVTypography.caption.weight(.semibold))
                .foregroundStyle(themeManager.accentColor)
            }
        }
    }

    private var navigationLinks: some View {
        GVCard {
            VStack(spacing: 0) {
                NavigationLink {
                    ConfigurationView()
                } label: {
                    NavRow(title: "Configuration", icon: "gearshape.fill")
                }
                Divider()
                NavigationLink {
                    AnalyticsView()
                        .environmentObject(appState)
                } label: {
                    NavRow(title: "Analytics & Insights", icon: "chart.bar.fill")
                }
                Divider()
                NavigationLink {
                    ShelvesView()
                        .environmentObject(appState)
                } label: {
                    NavRow(title: "Virtual Shelves", icon: "photo.on.rectangle.angled")
                }
            }
        }
    }

    private var achievementsCard: some View {
        GVCard {
            AchievementsSection(achievements: achievements)
        }
    }

    private var achievements: [Achievement] {
        AchievementEngine.evaluate(
            items: collectionStore.items,
            hoursBuilt: profileStore.profile?.hoursBuilt ?? 0,
            shelfCount: shelfStore.shelves.count
        )
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatBlock(title: "Kits", value: "\(collectionStore.stats.totalKits)")
            StatBlock(title: "Completed", value: "\(collectionStore.stats.completed)")
            StatBlock(title: "Hours", value: formatHours(profileStore.profile?.hoursBuilt ?? 0))
        }
    }

    private var membershipCard: some View {
        GVCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Membership")
                    .font(GVTypography.headline)

                if profileStore.tier == .pro {
                    Label("Pro — unlimited kits & cloud sync", systemImage: "star.fill")
                        .font(GVTypography.callout)
                        .foregroundStyle(themeManager.accentColor)
                    Button("Restore Purchases") {
                        Task { await subscriptionStore.restorePurchases() }
                    }
                    .font(GVTypography.callout)
                    .foregroundStyle(GVColors.textSecondary)
                } else {
                    Text("\(collectionStore.remainingFreeSlots) of \(SubscriptionConfig.freeKitLimit) free kit slots remaining.")
                        .font(GVTypography.callout)
                        .foregroundStyle(GVColors.textSecondary)
                    Button("Upgrade to Pro") { showPaywall = true }
                        .font(GVTypography.callout.weight(.semibold))
                        .foregroundStyle(themeManager.accentColor)
                }
            }
        }
    }

    @ViewBuilder
    private var syncCard: some View {
        if profileStore.tier == .pro {
            GVCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Cloud Sync")
                            .font(GVTypography.headline)
                        Spacer()
                        if collectionStore.isSyncing {
                            ProgressView()
                        }
                    }

                    if collectionStore.isCloudSyncEnabled {
                        Label("Sync enabled via Supabase", systemImage: "icloud.fill")
                            .font(GVTypography.callout)
                            .foregroundStyle(GVColors.success)
                        if let lastSynced = collectionStore.lastSyncedAt {
                            Text("Last synced \(lastSynced.formatted(date: .omitted, time: .shortened))")
                                .font(GVTypography.caption)
                                .foregroundStyle(GVColors.textSecondary)
                        }
                        Button("Sync Now") {
                            Task { await collectionStore.syncNow() }
                        }
                        .font(GVTypography.callout.weight(.semibold))
                        .foregroundStyle(themeManager.accentColor)
                    } else {
                        Text("Enable Cloud Sync in Configuration, or add Secrets.plist to connect Supabase.")
                            .font(GVTypography.caption)
                            .foregroundStyle(GVColors.textSecondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var demoCard: some View {
        if !SupabaseManager.shared.isConfigured {
            GVCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Demo mode")
                        .font(GVTypography.headline)
                    Text("Auth and profile saved locally. Use StoreKit config or Try Pro (Demo) in the paywall.")
                        .font(GVTypography.callout)
                        .foregroundStyle(GVColors.textSecondary)
                }
            }
        }
    }

    private var signOutButton: some View {
        Button(role: .destructive) {
            Task { await appState.signOut() }
        } label: {
            Text("Sign Out")
                .font(GVTypography.callout.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .background(GVColors.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func formatHours(_ hours: Double) -> String {
        if hours < 1 { return "<1" }
        return String(format: "%.0f", hours)
    }
}

private struct StatBlock: View {
    let title: String
    let value: String

    var body: some View {
        GVCard {
            VStack(spacing: 4) {
                Text(value)
                    .font(GVTypography.metric)
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
    ProfileView()
        .environmentObject(AppState.makeDefault(authService: MockAuthService.shared))
        .environmentObject(ProfileStore())
        .environmentObject(CollectionStore(context: PersistenceController.shared.mainContext, profileStore: ProfileStore()))
        .environmentObject(SubscriptionStore())
        .environmentObject(ShelfStore(context: PersistenceController.shared.mainContext, profileStore: ProfileStore()))
        .environmentObject(ThemeManager())
}
