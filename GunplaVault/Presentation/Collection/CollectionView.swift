import SwiftUI

struct CollectionView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var collectionStore: CollectionStore
    @EnvironmentObject private var profileStore: ProfileStore
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var showAddKit = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    GradeFilterRow(selectedGrade: $collectionStore.selectedGrade) {}

                    HStack {
                        Menu {
                            Picker("Sort", selection: $collectionStore.sort) {
                                ForEach(CollectionSort.allCases) { option in
                                    Text(option.label).tag(option)
                                }
                            }
                        } label: {
                            Label(collectionStore.sort.label, systemImage: "arrow.up.arrow.down")
                                .font(GVTypography.caption)
                                .foregroundStyle(themeManager.accentColor)
                        }

                        Spacer()

                        if profileStore.tier == .free {
                            Text("\(collectionStore.remainingFreeSlots)/\(SubscriptionConfig.freeKitLimit) free")
                                .font(GVTypography.caption)
                                .foregroundStyle(GVColors.textSecondary)
                        }
                    }

                    if collectionStore.filteredItems.isEmpty {
                        emptyState
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                            ForEach(collectionStore.filteredItems) { item in
                                NavigationLink(value: item.id) {
                                    CollectionKitCard(item: item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(GVColors.background)
            .navigationTitle("Collection")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $collectionStore.searchQuery, prompt: "Search kits")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        if collectionStore.isSyncing {
                            ProgressView()
                        } else if collectionStore.isCloudSyncEnabled {
                            Image(systemName: "icloud.fill")
                                .foregroundStyle(GVColors.success)
                                .font(.caption)
                        }
                        Button {
                            if collectionStore.canAddKit {
                                showAddKit = true
                            } else {
                                collectionStore.showPaywall = true
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(themeManager.accentColor)
                        }
                        .accessibilityLabel("Add kit")
                    }
                }
            }
            .navigationDestination(for: UUID.self) { id in
                if let item = collectionStore.item(id: id) {
                    KitDetailView(item: item)
                }
            }
            .sheet(isPresented: $showAddKit) {
                AddKitView()
            }
            .sheet(isPresented: $collectionStore.showPaywall) {
                PaywallView()
                    .environmentObject(appState)
            }
        }
    }

    private var emptyState: some View {
        GVCard {
            VStack(spacing: 14) {
                Image(systemName: "shippingbox")
                    .font(.system(size: 40))
                    .foregroundStyle(themeManager.accentColor.opacity(0.5))
                Text("No kits yet")
                    .font(GVTypography.headline)
                Text("Search the catalog or add a kit manually.")
                    .font(GVTypography.callout)
                    .foregroundStyle(GVColors.textSecondary)
                    .multilineTextAlignment(.center)
                GVPrimaryButton(title: "Add Your First Kit") {
                    showAddKit = true
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
}

struct CollectionKitCard: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let item: CollectionItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                BoxArtImage(urlString: item.boxArtURL, cornerRadius: 12)
                    .frame(height: 110)
                    .frame(maxWidth: .infinity)

                GVCapsuleBadge(text: item.grade.rawValue, tint: themeManager.accentColor)
                    .padding(8)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(GVTypography.callout.weight(.semibold))
                    .foregroundStyle(GVColors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack {
                    if item.status == .inProgress {
                        Text("\(item.buildProgressPercent)%")
                            .font(GVTypography.caption)
                            .foregroundStyle(themeManager.accentColor)
                    }
                    Spacer()
                    StatusBadge(status: item.status)
                }
            }
            .padding(10)
        }
        .background(GVColors.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(GVColors.border, lineWidth: 1)
        )
    }
}

#Preview {
    CollectionView()
        .environmentObject(AppState.makeDefault(authService: MockAuthService.shared))
        .environmentObject(CollectionStore(context: PersistenceController.shared.mainContext, profileStore: ProfileStore()))
        .environmentObject(ProfileStore())
        .environmentObject(ThemeManager())
}
