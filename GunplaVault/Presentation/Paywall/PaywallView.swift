import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var subscriptionStore: SubscriptionStore
    @EnvironmentObject private var profileStore: ProfileStore

    @State private var selectedPlan: Plan = .yearly

    private enum Plan {
        case monthly, yearly
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    comparisonCards
                    planPicker
                    purchaseButtons
                    restoreButton
                    demoButton
                    footerNotes
                }
                .padding(24)
            }
            .background(GVColors.background)
            .navigationTitle("Gunpla Vault Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .task {
                await subscriptionStore.bootstrap()
            }
            .onChange(of: subscriptionStore.isPro) { _, isPro in
                if isPro {
                    Task {
                        await appState.onProActivated()
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: Binding(
                get: { subscriptionStore.errorMessage != nil },
                set: { if !$0 { subscriptionStore.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(subscriptionStore.errorMessage ?? "")
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "star.hexagon.fill")
                .font(.system(size: 48))
                .foregroundStyle(GVColors.accent)
            Text("Upgrade to Pro")
                .font(GVTypography.title)
                .foregroundStyle(GVColors.textPrimary)
            Text("Unlimited kits, cloud sync across devices, and full build tracking.")
                .font(GVTypography.callout)
                .foregroundStyle(GVColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var comparisonCards: some View {
        VStack(spacing: 12) {
            GVCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Free")
                        .font(GVTypography.headline)
                    Label("Up to \(SubscriptionConfig.freeKitLimit) kits", systemImage: "checkmark.circle")
                    Label("Local storage only", systemImage: "checkmark.circle")
                    Label("Status tracking", systemImage: "checkmark.circle")
                }
                .font(GVTypography.callout)
                .foregroundStyle(GVColors.textSecondary)
            }

            GVCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pro")
                        .font(GVTypography.headline)
                        .foregroundStyle(GVColors.accent)
                    Label("Unlimited kits", systemImage: "infinity")
                    Label("iCloud-style cloud sync", systemImage: "icloud.fill")
                    Label("Full Build Mode (Phase 3)", systemImage: "hammer.fill")
                    Label("Analytics & export (Phase 4)", systemImage: "chart.bar.fill")
                }
                .font(GVTypography.callout)
                .foregroundStyle(GVColors.textSecondary)
            }
        }
    }

    @ViewBuilder
    private var planPicker: some View {
        if subscriptionStore.hasLoadedProducts {
            Picker("Plan", selection: $selectedPlan) {
                Text(monthlyLabel).tag(Plan.monthly)
                Text(yearlyLabel).tag(Plan.yearly)
            }
            .pickerStyle(.segmented)
        }
    }

    private var monthlyLabel: String {
        if let product = subscriptionStore.monthlyProduct {
            return "Monthly · \(product.displayPrice)"
        }
        return "Monthly"
    }

    private var yearlyLabel: String {
        if let product = subscriptionStore.yearlyProduct {
            return "Yearly · \(product.displayPrice)"
        }
        return "Yearly"
    }

    private var purchaseButtons: some View {
        GVPrimaryButton(
            title: purchaseTitle,
            isLoading: subscriptionStore.isLoading
        ) {
            Task {
                switch selectedPlan {
                case .monthly: await subscriptionStore.purchaseMonthly()
                case .yearly: await subscriptionStore.purchaseYearly()
                }
            }
        }
    }

    private var purchaseTitle: String {
        if subscriptionStore.hasLoadedProducts {
            return selectedPlan == .yearly ? "Subscribe Yearly" : "Subscribe Monthly"
        }
        return "Subscribe"
    }

    private var restoreButton: some View {
        Button("Restore Purchases") {
            Task { await subscriptionStore.restorePurchases() }
        }
        .font(GVTypography.callout)
        .foregroundStyle(GVColors.accent)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var demoButton: some View {
        if !SupabaseManager.shared.isConfigured || !subscriptionStore.hasLoadedProducts {
            Button("Try Pro (Demo Mode)") {
                Task { await subscriptionStore.activateDemoPro() }
            }
            .font(GVTypography.callout)
            .foregroundStyle(GVColors.textSecondary)
            .frame(maxWidth: .infinity)
        }
    }

    private var footerNotes: some View {
        VStack(spacing: 8) {
            Text("Payment will be charged to your Apple ID. Subscriptions auto-renew unless cancelled at least 24 hours before the end of the period.")
                .font(GVTypography.caption)
                .foregroundStyle(GVColors.textSecondary)
                .multilineTextAlignment(.center)

            if !SupabaseManager.shared.isConfigured {
                Text("Demo mode: Pro features work locally without App Store billing.")
                    .font(GVTypography.caption)
                    .foregroundStyle(GVColors.warning)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

#Preview {
    PaywallView()
        .environmentObject(AppState.makeDefault())
        .environmentObject(SubscriptionStore())
        .environmentObject(ProfileStore())
}
