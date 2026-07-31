import SwiftUI

struct WelcomeView: View {
    @ObservedObject var viewModel: AuthViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Spacer(minLength: 40)

                VStack(spacing: 12) {
                    BrandMarkView(stage: .complete, size: 88)

                    Text("GUNPLA VAULT")
                        .font(GVTypography.largeTitle)
                        .foregroundStyle(GVColors.textPrimary)
                        .accessibilityAddTraits(.isHeader)

                    Text("Build. Collect. Remember.")
                        .font(GVTypography.callout)
                        .foregroundStyle(GVColors.textSecondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Gunpla Vault. Build. Collect. Remember.")

                VStack(spacing: 12) {
                    FeatureRow(icon: "shippingbox.fill", title: "Your Collection", subtitle: "All your kits, organized beautifully")
                    FeatureRow(icon: "viewfinder", title: "AI Scanner", subtitle: "Smart recognition — coming in v1.1")
                    FeatureRow(icon: "chart.bar.fill", title: "Insights", subtitle: "Analytics that help you build better")
                    FeatureRow(icon: "lock.shield.fill", title: "Secure & Private", subtitle: "Your data is always protected")
                }

                if viewModel.usesMockAuth {
                    GVCapsuleBadge(text: "Demo Mode", tint: GVColors.warning)
                }

                GVPrimaryButton(title: "Get Started") {
                    viewModel.step = .email
                }

                Spacer(minLength: 24)
            }
            .padding(.horizontal, 24)
        }
    }
}

struct EmailEntryView: View {
    @ObservedObject var viewModel: AuthViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ScreenHeader(
                title: "Sign in",
                subtitle: "We'll email you a one-time code. No password needed."
            )

            GVTextField(
                title: "Email",
                text: $viewModel.email,
                keyboardType: .emailAddress,
                textContentType: .emailAddress
            )

            if let info = viewModel.infoMessage {
                Text(info)
                    .font(GVTypography.callout)
                    .foregroundStyle(GVColors.textSecondary)
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(GVTypography.callout)
                    .foregroundStyle(.red)
            }

            GVPrimaryButton(
                title: "Send Code",
                isLoading: viewModel.isLoading,
                isDisabled: viewModel.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ) {
                Task { await viewModel.sendOTP() }
            }

            Spacer()
        }
        .padding(24)
        .navigationBarBackButtonHidden(false)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Back") { viewModel.step = .welcome }
                    .foregroundStyle(GVColors.accent)
            }
        }
    }
}

struct OTPEntryView: View {
    @ObservedObject var viewModel: AuthViewModel
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ScreenHeader(
                title: "Enter code",
                subtitle: "Sent to \(viewModel.email)"
            )

            GVTextField(
                title: "6-digit code",
                text: $viewModel.otp,
                keyboardType: .numberPad,
                textContentType: .oneTimeCode
            )
            .focused($isFocused)

            if let info = viewModel.infoMessage {
                Text(info)
                    .font(GVTypography.callout)
                    .foregroundStyle(GVColors.textSecondary)
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(GVTypography.callout)
                    .foregroundStyle(.red)
            }

            GVPrimaryButton(
                title: "Verify",
                isLoading: viewModel.isLoading,
                isDisabled: viewModel.otp.count < 6
            ) {
                Task { await viewModel.verifyOTP() }
            }

            Button("Resend code") {
                Task { await viewModel.sendOTP() }
            }
            .font(GVTypography.callout)
            .foregroundStyle(GVColors.accent)

            Spacer()
        }
        .padding(24)
        .onAppear { isFocused = true }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Back") { viewModel.step = .email }
                    .foregroundStyle(GVColors.accent)
            }
        }
    }
}

struct ProfileSetupView: View {
    @ObservedObject var viewModel: AuthViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ScreenHeader(
                title: "Welcome, Builder",
                subtitle: "Set up your profile. You can change this later."
            )

            GVTextField(title: "Display name", text: $viewModel.displayName, textContentType: .name)

            GVCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Membership")
                        .font(GVTypography.headline)
                        .foregroundStyle(GVColors.textPrimary)
                    Text("You're on the Free plan. Pro features unlock with a subscription in a later phase.")
                        .font(GVTypography.callout)
                        .foregroundStyle(GVColors.textSecondary)
                    GVCapsuleBadge(text: SubscriptionTier.free.displayName)
                }
            }

            GVPrimaryButton(
                title: "Continue to App",
                isLoading: viewModel.isLoading,
                isDisabled: viewModel.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ) {
                Task { await viewModel.completeProfile() }
            }

            Spacer()
        }
        .padding(24)
    }
}

private struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(GVColors.accent)
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(GVTypography.headline)
                    .foregroundStyle(GVColors.textPrimary)
                Text(subtitle)
                    .font(GVTypography.caption)
                    .foregroundStyle(GVColors.textSecondary)
            }
            Spacer()
        }
        .padding(14)
        .background(GVColors.surface, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview("Welcome") {
    WelcomeView(viewModel: AuthViewModel(onComplete: { _, _ in }))
}
