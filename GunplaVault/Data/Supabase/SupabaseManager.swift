import Foundation
import Supabase

final class SupabaseManager: Sendable {
    static let shared = SupabaseManager()

    let client: SupabaseClient?

    private init() {
        guard
            let urlString = Secrets.supabaseURL,
            let url = URL(string: urlString),
            let anonKey = Secrets.supabaseAnonKey,
            !anonKey.isEmpty,
            !urlString.contains("YOUR_PROJECT")
        else {
            client = nil
            return
        }

        client = SupabaseClient(supabaseURL: url, supabaseKey: anonKey)
    }

    var isConfigured: Bool { client != nil }
}

enum Secrets {
    private static let plist: [String: Any]? = {
        guard
            let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        else { return nil }
        return dict
    }()

    static var supabaseURL: String? {
        plist?["SUPABASE_URL"] as? String
            ?? ProcessInfo.processInfo.environment["SUPABASE_URL"]
    }

    static var supabaseAnonKey: String? {
        plist?["SUPABASE_ANON_KEY"] as? String
            ?? ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"]
    }
}
