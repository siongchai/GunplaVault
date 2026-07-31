import SwiftUI

struct ManualKitEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var collectionStore: CollectionStore

    @State private var name = ""
    @State private var series = ""
    @State private var grade: KitGrade = .hg
    @State private var scale = "1/144"
    @State private var releaseYear = Calendar.current.component(.year, from: Date())
    @State private var pricePaid = ""
    @State private var notes = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ScreenHeader(
                        title: "Manual Entry",
                        subtitle: "Add a kit that isn't in the catalog."
                    )

                    GVTextField(title: "Kit name", text: $name)
                    GVTextField(title: "Series", text: $series)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Grade")
                            .font(GVTypography.caption)
                            .foregroundStyle(GVColors.textSecondary)
                        Picker("Grade", selection: $grade) {
                            ForEach(KitGrade.allCases) { g in
                                Text(g.rawValue).tag(g)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    GVTextField(title: "Scale", text: $scale)

                    Stepper("Release year: \(releaseYear)", value: $releaseYear, in: 1979...2030)

                    GVTextField(title: "Price paid (optional)", text: $pricePaid, keyboardType: .decimalPad)

                    GVTextField(title: "Notes (optional)", text: $notes)

                    GVPrimaryButton(
                        title: "Add to Collection",
                        isDisabled: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ) {
                        save()
                    }
                }
                .padding(20)
            }
            .background(GVColors.background)
            .navigationTitle("Manual Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $collectionStore.showPaywall) {
                PaywallView()
            }
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

    private func save() {
        let price = Double(pricePaid.trimmingCharacters(in: .whitespacesAndNewlines))
        do {
            try collectionStore.addManual(
                name: name,
                series: series.isEmpty ? "Custom" : series,
                grade: grade,
                scale: scale,
                releaseYear: releaseYear,
                pricePaid: price,
                notes: notes.isEmpty ? nil : notes
            )
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

#Preview {
    ManualKitEntryView()
        .environmentObject(CollectionStore(context: PersistenceController.shared.mainContext, profileStore: ProfileStore()))
}
