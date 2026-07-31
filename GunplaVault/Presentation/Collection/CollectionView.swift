import SwiftUI

struct CollectionView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var collectionStore: CollectionStore
    @EnvironmentObject private var profileStore: ProfileStore

    @State private var showAddKit = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        ScreenHeader(
                            title: "Collection",
                            subtitle: "\(collectionStore.stats.totalKits) kits · \(profileStore.tier.displayName) plan"
                        )
                        Spacer()
                    }

                    HStack {
                        GVTextField(title: "Search", text: $collectionStore.searchQuery)
                    }

                    GradeFilterRow(selectedGrade: $collectionStore.selectedGrade) {}

                    HStack {
                        Menu {
                            Picker("Sort", selection: $collectionStore.sort) {
                                ForEach(CollectionSort.allCases) { option in
                                    Text(option.label).tag(option)
                                }
                            }
                        } label: {
                            Label("Sort: \(collectionStore.sort.label)", systemImage: "arrow.up.arrow.down")
                                .font(GVTypography.caption)
                                .foregroundStyle(GVColors.accent)
                        }
                        Spacer()
                        if profileStore.tier == .free {
                            Text("\(collectionStore.remainingFreeSlots)/\(SubscriptionConfig.freeKitLimit) free slots")
                                .font(GVTypography.caption)
                                .foregroundStyle(GVColors.textSecondary)
                        }
                    }

                    if collectionStore.filteredItems.isEmpty {
                        GVCard {
                            VStack(spacing: 12) {
                                Image(systemName: "shippingbox")
                                    .font(.largeTitle)
                                    .foregroundStyle(GVColors.accent.opacity(0.5))
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
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
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
                            Image(systemName: "plus")
                        }
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
}

private struct CollectionKitCard: View {
    let item: CollectionItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 10)
                .fill(GVColors.surfaceSecondary)
                .frame(height: 100)
                .overlay {
                    Image(systemName: "shippingbox.fill")
                        .font(.largeTitle)
                        .foregroundStyle(GVColors.accent.opacity(0.5))
                }

            HStack {
                GVCapsuleBadge(text: item.grade.rawValue)
                Spacer()
                StatusBadge(status: item.status)
            }

            Text(item.name)
                .font(GVTypography.caption)
                .foregroundStyle(GVColors.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .padding(10)
        .background(GVColors.surface, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(GVColors.border, lineWidth: 1))
    }
}

#Preview {
    CollectionView()
        .environmentObject(CollectionStore(context: PersistenceController.shared.mainContext, profileStore: ProfileStore()))
        .environmentObject(ProfileStore())
}
