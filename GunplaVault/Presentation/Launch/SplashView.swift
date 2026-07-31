import SwiftUI

struct SplashView: View {
    /// Bootstrap finished; splash may exit after the animation completes.
    var isAppReady: Bool
    var onFinished: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var stage: BrandMarkStage = .wireframe
    @State private var assemblyProgress: CGFloat = 0
    @State private var showTitle = false
    @State private var showTagline = false
    @State private var animationDone = false

    private let markSize: CGFloat = 128

    var body: some View {
        ZStack {
            GVColors.background.ignoresSafeArea()

            VStack(spacing: 20) {
                BrandMarkView(stage: stage, size: markSize, assemblyProgress: assemblyProgress)

                VStack(spacing: 8) {
                    Text("GUNPLA VAULT")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .tracking(3)
                        .foregroundStyle(GVColors.textPrimary)
                        .opacity(showTitle ? 1 : 0)
                        .offset(y: showTitle ? 0 : 8)

                    Text("Build. Collect. Remember.")
                        .font(GVTypography.callout)
                        .foregroundStyle(GVColors.textSecondary)
                        .opacity(showTagline ? 1 : 0)
                        .offset(y: showTagline ? 0 : 6)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Gunpla Vault is loading")
        }
        .task { await runSequence() }
        .onChange(of: isAppReady) { _, ready in
            if ready { tryFinish() }
        }
        .onChange(of: animationDone) { _, done in
            if done { tryFinish() }
        }
    }

    private func tryFinish() {
        guard isAppReady, animationDone else { return }
        onFinished()
    }

    @MainActor
    private func runSequence() async {
        if reduceMotion {
            stage = .complete
            assemblyProgress = 1
            showTitle = true
            showTagline = true
            try? await Task.sleep(for: .milliseconds(400))
            animationDone = true
            return
        }

        try? await Task.sleep(for: .milliseconds(350))
        stage = .wireframe

        try? await Task.sleep(for: .milliseconds(650))
        stage = .assembling
        withAnimation(.easeInOut(duration: 0.85)) {
            assemblyProgress = 1
        }
        try? await Task.sleep(for: .milliseconds(900))

        stage = .poweringUp
        withAnimation(.easeOut(duration: 0.55)) {
            assemblyProgress = 1
        }
        try? await Task.sleep(for: .milliseconds(700))

        stage = .complete
        withAnimation(.easeOut(duration: 0.45)) {
            showTitle = true
        }
        try? await Task.sleep(for: .milliseconds(280))
        withAnimation(.easeOut(duration: 0.35)) {
            showTagline = true
        }
        try? await Task.sleep(for: .milliseconds(550))

        animationDone = true
    }
}

#Preview {
    SplashView(isAppReady: true, onFinished: {})
        .environmentObject(ThemeManager())
}
