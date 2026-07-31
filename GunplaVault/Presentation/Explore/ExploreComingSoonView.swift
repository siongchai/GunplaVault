import SwiftUI

struct ExploreComingSoonView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "safari")
                    .font(.system(size: 56))
                    .foregroundStyle(GVColors.accent.opacity(0.6))

                VStack(spacing: 8) {
                    Text("Explore")
                        .font(GVTypography.title)
                        .foregroundStyle(GVColors.textPrimary)
                    Text("Coming soon")
                        .font(GVTypography.headline)
                        .foregroundStyle(GVColors.accent)
                    Text("Discover releases, community builds, and inspiration — planned for a future update.")
                        .font(GVTypography.callout)
                        .foregroundStyle(GVColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                GVCapsuleBadge(text: "Phase 5+", tint: GVColors.textSecondary)

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(GVColors.background)
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ExploreComingSoonView()
}
