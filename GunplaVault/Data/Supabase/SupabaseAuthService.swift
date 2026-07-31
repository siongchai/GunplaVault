import Foundation
import Supabase

actor SupabaseAuthService: AuthService {
    static let shared = SupabaseAuthService()

    private init() {}

    private var client: SupabaseClient? {
        SupabaseManager.shared.client
    }

    func restoreSession() async -> AuthSession? {
        guard let client else { return nil }
        do {
            let session = try await client.auth.session
            return AuthSession(
                userID: session.user.id.uuidString,
                email: session.user.email ?? "",
                accessToken: session.accessToken
            )
        } catch {
            return nil
        }
    }

    func sendOTP(to email: String) async throws {
        guard let client else { throw AuthError.notConfigured }
        guard email.contains("@") else { throw AuthError.invalidEmail }

        do {
            try await client.auth.signInWithOTP(
                email: email,
                redirectTo: nil,
                shouldCreateUser: true
            )
        } catch {
            throw AuthError.network(error.localizedDescription)
        }
    }

    func verifyOTP(email: String, code: String) async throws -> AuthSession {
        guard let client else { throw AuthError.notConfigured }
        guard code.count >= 6 else { throw AuthError.invalidOTP }

        do {
            let response = try await client.auth.verifyOTP(
                email: email,
                token: code,
                type: .email
            )
            guard let session = response.session else {
                throw AuthError.invalidOTP
            }
            return AuthSession(
                userID: session.user.id.uuidString,
                email: session.user.email ?? email,
                accessToken: session.accessToken
            )
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.network(error.localizedDescription)
        }
    }

    func signOut() async {
        guard let client else { return }
        try? await client.auth.signOut()
    }
}

/// Offline-friendly auth for previews and when Supabase is not configured.
final class MockAuthService: AuthService, @unchecked Sendable {
    static let shared = MockAuthService()

    private var session: AuthSession?

    private static let sessionKey = "gv.mockAuthSession"

    private init() {
        session = Self.loadStoredSession()
    }

    func restoreSession() async -> AuthSession? {
        session ?? Self.loadStoredSession()
    }

    func sendOTP(to email: String) async throws {
        guard email.contains("@") else { throw AuthError.invalidEmail }
    }

    func verifyOTP(email: String, code: String) async throws -> AuthSession {
        guard code == "123456" else { throw AuthError.invalidOTP }
        let newSession = AuthSession(userID: UUID().uuidString, email: email, accessToken: "mock")
        session = newSession
        Self.storeSession(newSession)
        return newSession
    }

    func signOut() async {
        session = nil
        UserDefaults.standard.removeObject(forKey: Self.sessionKey)
    }

    private static func storeSession(_ session: AuthSession) {
        let payload: [String: String] = [
            "userID": session.userID,
            "email": session.email,
            "accessToken": session.accessToken
        ]
        UserDefaults.standard.set(payload, forKey: sessionKey)
    }

    private static func loadStoredSession() -> AuthSession? {
        guard let payload = UserDefaults.standard.dictionary(forKey: sessionKey) as? [String: String],
              let userID = payload["userID"],
              let email = payload["email"],
              let token = payload["accessToken"]
        else { return nil }
        return AuthSession(userID: userID, email: email, accessToken: token)
    }
}
