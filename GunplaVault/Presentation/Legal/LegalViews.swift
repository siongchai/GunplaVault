import SwiftUI

enum LegalDocument: String, Identifiable {
    case privacy
    case terms

    var id: String { rawValue }

    var title: String {
        switch self {
        case .privacy: return "Privacy Policy"
        case .terms: return "Terms of Use"
        }
    }
}

struct LegalDocumentView: View {
    let document: LegalDocument

    var body: some View {
        ScrollView {
            Text(content)
                .font(GVTypography.body)
                .foregroundStyle(GVColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
        }
        .background(GVColors.background)
        .navigationTitle(document.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var content: String {
        switch document {
        case .privacy: return Self.privacyPolicy
        case .terms: return Self.termsOfUse
        }
    }

    private static let privacyPolicy = """
    Last updated: July 2026

    Gunpla Vault ("we", "our", or "the app") helps you catalog and track your Gunpla collection. This policy describes what data we collect and how we use it.

    Information You Provide
    • Email address for sign-in (one-time passcode via Supabase Auth)
    • Display name and optional profile details
    • Collection data: kit names, grades, prices, build notes, photos you add

    Data Storage
    • Free tier: collection data is stored locally on your device.
    • Pro tier: collection data may sync to Supabase cloud storage tied to your account.
    • Build and shelf photos are stored on your device unless you enable cloud sync (Pro).

    Third-Party Services
    • Supabase — authentication and cloud database (Pro sync)
    • Apple StoreKit — subscription purchases and restore

    We do not sell your personal data. We do not use third-party advertising trackers.

    Your Choices
    • Sign out to clear the local session
    • Delete the app to remove local data
    • Contact us to request account or cloud data deletion

    Children's Privacy
    Gunpla Vault is not directed at children under 13.

    Contact
    privacy@gunplavault.app
    """

    private static let termsOfUse = """
    Last updated: July 2026

    By using Gunpla Vault you agree to these terms.

    License
    We grant you a personal, non-transferable license to use the app on Apple devices you own or control.

    Subscriptions (Pro)
    • Pro is billed through Apple's In-App Purchase system
    • Subscriptions auto-renew unless cancelled at least 24 hours before the period ends
    • Manage or cancel in Settings → Apple ID → Subscriptions
    • Restore purchases on a new device via Profile or the paywall

    Acceptable Use
    You agree not to misuse the app, attempt unauthorized access to our systems, or upload unlawful content.

    Content
    You retain ownership of collection entries and photos you create. You grant us the rights needed to store and sync that content when you use cloud features.

    Disclaimer
    Gunpla Vault is provided "as is" without warranty. Kit catalog seed data is for reference; we do not guarantee accuracy of third-party product information.

    Limitation of Liability
    To the extent permitted by law, we are not liable for indirect or consequential damages arising from use of the app.

    Changes
    We may update these terms. Continued use after changes constitutes acceptance.

    Contact
    support@gunplavault.app
    """
}
