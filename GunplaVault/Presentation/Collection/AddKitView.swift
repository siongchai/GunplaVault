import SwiftUI

struct AddKitView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var collectionStore: CollectionStore

    @State private var query = ""
    @State private var selectedGrade: KitGrade?
    @State private var results: [SeedKit] = []
    @State private var catalogCount = 0
    @State private var errorMessage: String?
    @State private var showManualEntry = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    GVTextField(title: "Search catalog", text: $query)
                        .onChange(of: query) { _, _ in runSearch() }

                    GradeFilterRow(selectedGrade: $selectedGrade) {
                        runSearch()
                    }

                    if !collectionStore.canAddKit {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(GVColors.warning)
                            Text("Free limit reached (\(SubscriptionConfig.freeKitLimit) kits)")
                                .font(GVTypography.caption)
                                .foregroundStyle(GVColors.textSecondary)
                        }
                    } else if collectionStore.remainingFreeSlots < SubscriptionConfig.freeKitLimit {
                        Text("\(collectionStore.remainingFreeSlots) free slots remaining")
                            .font(GVTypography.caption)
                            .foregroundStyle(GVColors.textSecondary)
                    }

                    Text("\(catalogCount) kits in catalog")
                        .font(GVTypography.caption)
                        .foregroundStyle(GVColors.textSecondary)
                }
                .padding(16)

                List {
                    ForEach(results) { kit in
                        Button {
                            addKit(kit)
                        } label: {
                            SeedKitRow(kit: kit, isOwned: collectionStore.items.contains { $0.seedKitID == kit.id })
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listStyle(.plain)
            }
            .background(GVColors.background)
            .navigationTitle("Add Kit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Manual") { showManualEntry = true }
                }
            }
            .sheet(isPresented: $showManualEntry) {
                ManualKitEntryView()
            }
            .sheet(isPresented: $collectionStore.showPaywall) {
                PaywallView()
            }
            .onAppear { runSearch() }
            .alert("Error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func runSearch() {
        do {
            results = try SeedKitCatalog.shared.search(query: query, grade: selectedGrade)
            catalogCount = SeedKitCatalog.shared.count
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func addKit(_ kit: SeedKit) {
        do {
            try collectionStore.addFromSeed(kit)
            dismiss()
        } catch let error as CollectionError {
            if case .freeLimitReached = error {
                collectionStore.showPaywall = true
            } else {
                errorMessage = error.localizedDescription
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct GradeFilterRow: View {
    @Binding var selectedGrade: KitGrade?
    var onChange: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: selectedGrade == nil) {
                    selectedGrade = nil
                    onChange()
                }
                ForEach(KitGrade.allCases) { grade in
                    FilterChip(title: grade.rawValue, isSelected: selectedGrade == grade) {
                        selectedGrade = grade
                        onChange()
                    }
                }
            }
        }
    }
}

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(GVTypography.caption)
                .foregroundStyle(isSelected ? .white : GVColors.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? GVColors.accent : GVColors.surfaceSecondary, in: Capsule())
        }
    }
}

private struct SeedKitRow: View {
    let kit: SeedKit
    let isOwned: Bool

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(GVColors.surfaceSecondary)
                .frame(width: 52, height: 52)
                .overlay {
                    Image(systemName: "shippingbox.fill")
                        .foregroundStyle(GVColors.accent.opacity(0.5))
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(kit.name)
                    .font(GVTypography.headline)
                    .foregroundStyle(GVColors.textPrimary)
                Text("\(kit.grade.rawValue) · \(kit.series)")
                    .font(GVTypography.caption)
                    .foregroundStyle(GVColors.textSecondary)
            }

            Spacer()

            if isOwned {
                GVCapsuleBadge(text: "Owned", tint: GVColors.success)
            } else {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(GVColors.accent)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    AddKitView()
        .environmentObject(CollectionStore(context: PersistenceController.shared.mainContext, profileStore: ProfileStore()))
}
