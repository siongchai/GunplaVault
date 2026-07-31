import Foundation
import StoreKit

@MainActor
final class SubscriptionStore: ObservableObject {
    @Published private(set) var isPro = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let manager = SubscriptionManager.shared
    private weak var profileStore: ProfileStore?

    var products: [Product] { manager.products }
    var monthlyProduct: Product? { manager.monthlyProduct }
    var yearlyProduct: Product? { manager.yearlyProduct }
    var hasLoadedProducts: Bool { manager.hasLoadedProducts }

    func bind(profileStore: ProfileStore) {
        self.profileStore = profileStore
    }

    func bootstrap() async {
        await manager.loadProducts()
        await manager.refreshEntitlements()
        isPro = manager.isPro || profileStore?.tier == .pro
        if isPro {
            await syncTierToProfile()
        }
    }

    func purchaseMonthly() async {
        guard let product = monthlyProduct else {
            errorMessage = SubscriptionError.productNotFound.localizedDescription
            return
        }
        await purchase(product)
    }

    func purchaseYearly() async {
        guard let product = yearlyProduct else {
            errorMessage = SubscriptionError.productNotFound.localizedDescription
            return
        }
        await purchase(product)
    }

    func activateDemoPro() async {
        isPro = true
        successMessage = "Pro activated (demo mode)."
        await syncTierToProfile()
    }

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        await manager.restorePurchases()
        isPro = manager.isPro
        if isPro {
            successMessage = "Pro subscription restored."
            await syncTierToProfile()
        } else {
            errorMessage = manager.errorMessage ?? "No active subscription found."
        }
    }

    func refresh() async {
        await manager.refreshEntitlements()
        isPro = manager.isPro || profileStore?.tier == .pro
        await syncTierToProfile()
    }

    private func purchase(_ product: Product) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer { isLoading = false }

        do {
            try await manager.purchase(product)
            isPro = manager.isPro
            if isPro {
                successMessage = "Welcome to Pro!"
                await syncTierToProfile()
            }
        } catch let error as SubscriptionError {
            if case .userCancelled = error { return }
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func syncTierToProfile() async {
        let tier: SubscriptionTier = isPro ? .pro : .free
        await profileStore?.setTier(tier)
    }
}
