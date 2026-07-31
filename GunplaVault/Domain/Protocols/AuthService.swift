import Foundation

protocol AuthService: Sendable {
    func restoreSession() async -> AuthSession?
    func sendOTP(to email: String) async throws
    func verifyOTP(email: String, code: String) async throws -> AuthSession
    func signOut() async
}

enum AuthError: LocalizedError {
    case notConfigured
    case invalidEmail
    case invalidOTP
    case network(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Supabase is not configured. Add your project URL and anon key in Secrets.plist."
        case .invalidEmail:
            return "Enter a valid email address."
        case .invalidOTP:
            return "Invalid or expired code. Request a new one."
        case .network(let message):
            return message
        }
    }
}
