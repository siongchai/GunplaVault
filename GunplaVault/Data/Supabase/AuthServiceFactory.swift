import Foundation

enum AuthServiceFactory {
    static var current: AuthService {
        if SupabaseManager.shared.isConfigured {
            return SupabaseAuthService.shared
        }
        return MockAuthService.shared
    }
}
