import SwiftUI

@MainActor
final class AuthViewModel: ObservableObject {
    enum Step {
        case welcome
        case email
        case otp
        case profile
    }

    @Published var step: Step = .welcome
    @Published var email = ""
    @Published var otp = ""
    @Published var displayName = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var infoMessage: String?

    private var pendingSession: AuthSession?

    private let authService: AuthService
    private let onComplete: (AuthSession, String) async -> Void

    init(
        authService: AuthService = AuthServiceFactory.current,
        onComplete: @escaping (AuthSession, String) async -> Void
    ) {
        self.authService = authService
        self.onComplete = onComplete
    }

    var usesMockAuth: Bool {
        authService is MockAuthService || !SupabaseManager.shared.isConfigured
    }

    func sendOTP() async {
        errorMessage = nil
        infoMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            try await authService.sendOTP(to: email.trimmingCharacters(in: .whitespacesAndNewlines))
            infoMessage = usesMockAuth
                ? "Demo mode: enter 123456 as your code."
                : "Check your email for a 6-digit code."
            step = .otp
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func verifyOTP() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let session = try await authService.verifyOTP(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                code: otp.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            pendingSession = session
            step = .profile
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func completeProfile() async {
        guard let pendingSession else { return }
        isLoading = true
        defer { isLoading = false }
        await onComplete(pendingSession, displayName.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}

struct AuthFlowView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        AuthFlowScreen { session, displayName in
            await appState.finishOnboarding(session: session, displayName: displayName)
        }
    }
}

struct AuthFlowScreen: View {
    let onComplete: (AuthSession, String) async -> Void
    @StateObject private var viewModel: AuthViewModel

    init(onComplete: @escaping (AuthSession, String) async -> Void) {
        self.onComplete = onComplete
        _viewModel = StateObject(wrappedValue: AuthViewModel(onComplete: onComplete))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GVColors.background.ignoresSafeArea()
                switch viewModel.step {
                case .welcome:
                    WelcomeView(viewModel: viewModel)
                case .email:
                    EmailEntryView(viewModel: viewModel)
                case .otp:
                    OTPEntryView(viewModel: viewModel)
                case .profile:
                    ProfileSetupView(viewModel: viewModel)
                }
            }
        }
    }
}

#Preview {
    AuthFlowView()
        .environmentObject(AppState.makeDefault(authService: MockAuthService.shared))
}
