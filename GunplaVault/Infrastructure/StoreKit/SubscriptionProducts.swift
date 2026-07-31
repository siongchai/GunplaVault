import Foundation

enum SubscriptionProducts {
    static let monthly = "com.gunplavault.app.pro.monthly"
    static let yearly = "com.gunplavault.app.pro.yearly"

    static let all = [monthly, yearly]
}

enum SubscriptionError: LocalizedError {
    case productNotFound
    case purchasePending
    case userCancelled
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Subscription product not found. Use the StoreKit configuration in Xcode for simulator testing."
        case .purchasePending:
            return "Purchase is pending approval."
        case .userCancelled:
            return "Purchase cancelled."
        case .failed(let message):
            return message
        }
    }
}
