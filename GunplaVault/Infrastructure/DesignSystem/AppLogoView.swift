import SwiftUI

/// Renders the same artwork as the home-screen app icon, with optional splash animation stages.
struct AppLogoView: View {
    var stage: BrandMarkStage = .complete
    var assemblyProgress: CGFloat = 1
    var size: CGFloat = 128

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    private var cornerRadius: CGFloat { size * 0.2237 }

    private var logoOpacity: Double {
        switch stage {
        case .wireframe: return 0.32
        case .assembling: return 0.32 + Double(assemblyProgress) * 0.68
        case .poweringUp, .complete: return 1
        }
    }

    private var logoScale: CGFloat {
        switch stage {
        case .wireframe: return 0.86
        case .assembling: return 0.86 + assemblyProgress * 0.14
        case .poweringUp, .complete: return 1
        }
    }

    private var logoBlur: CGFloat {
        switch stage {
        case .wireframe: return 10
        case .assembling: return 10 * (1 - assemblyProgress)
        case .poweringUp, .complete: return 0
        }
    }

    private var glowOpacity: Double {
        switch stage {
        case .wireframe, .assembling: return 0
        case .poweringUp: return 0.35 + Double(assemblyProgress) * 0.45
        case .complete: return 0.55
        }
    }

    var body: some View {
        ZStack {
            if stage == .poweringUp || stage == .complete {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [themeManager.accentColor.opacity(glowOpacity), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: size * 0.72
                        )
                    )
                    .frame(width: size * 1.35, height: size * 1.35)
                    .blur(radius: 8)
            }

            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            stage == .wireframe ? themeManager.accentColor.opacity(0.55) : .clear,
                            lineWidth: 2
                        )
                }
                .shadow(
                    color: .black.opacity(colorScheme == .dark ? 0.35 : 0.12),
                    radius: stage == .complete ? 16 : 8,
                    y: 6
                )
                .opacity(logoOpacity)
                .scaleEffect(logoScale)
                .blur(radius: logoBlur)
                .saturation(stage == .wireframe ? 0.25 : 1)
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Gunpla Vault")
    }
}

#Preview("Splash stages") {
    VStack(spacing: 24) {
        HStack(spacing: 20) {
            AppLogoView(stage: .wireframe, size: 72)
            AppLogoView(stage: .assembling, assemblyProgress: 0.5, size: 72)
        }
        HStack(spacing: 20) {
            AppLogoView(stage: .poweringUp, assemblyProgress: 0.8, size: 72)
            AppLogoView(stage: .complete, size: 72)
        }
    }
    .padding()
    .background(GVColors.background)
    .environmentObject(ThemeManager())
}
