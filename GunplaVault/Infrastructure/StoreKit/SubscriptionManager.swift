import Foundation
import StoreKit

@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    @Published private(set) var products: [Product] = []
    @Published private(set) var isPro = false
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private var transactionListener: Task<Void, Never>?

    private init() {
        transactionListener = Task { await listenForTransactions() }
    }

    deinit {
        transactionListener?.cancel()
    }

    var monthlyProduct: Product? {
        products.first { $0.id == SubscriptionProducts.monthly }
    }

    var yearlyProduct: Product? {
        products.first { $0.id == SubscriptionProducts.yearly }
    }

    var hasLoadedProducts: Bool { !products.isEmpty }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            products = try await Product.products(for: SubscriptionProducts.all)
                .sorted { $0.price < $1.price }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshEntitlements() async {
        var entitled = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if SubscriptionProducts.all.contains(transaction.productID) {
                entitled = true
                break
            }
        }
        isPro = entitled
    }

    func purchase(_ product: Product) async throws {
        isLoading = true
        defer { isLoading = false }

        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await refreshEntitlements()
        case .userCancelled:
            throw SubscriptionError.userCancelled
        case .pending:
            throw SubscriptionError.purchasePending
        @unknown default:
            throw SubscriptionError.failed("Unknown purchase result.")
        }
    }

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            guard case .verified(let transaction) = result else { continue }
            await transaction.finish()
            await refreshEntitlements()
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw SubscriptionError.failed(error.localizedDescription)
        case .verified(let value):
            return value
        }
    }
}
