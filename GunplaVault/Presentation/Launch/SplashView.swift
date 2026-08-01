import SwiftUI

// MARK: - Phase model

enum SplashPhase: Int, CaseIterable, Comparable {
    case initialize
    case assembling
    case poweringUp
    case lockup

    static func < (lhs: SplashPhase, rhs: SplashPhase) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var hold: Duration {
        switch self {
        case .initialize: return .milliseconds(550)
        case .assembling: return .milliseconds(700)
        case .poweringUp: return .milliseconds(600)
        case .lockup: return .milliseconds(800)
        }
    }

    var transition: Animation {
        switch self {
        case .initialize: return .easeOut(duration: 0.35)
        case .assembling: return .easeInOut(duration: 0.5)
        case .poweringUp: return .spring(response: 0.55, dampingFraction: 0.78)
        case .lockup: return .easeOut(duration: 0.45)
        }
    }

    var caption: String? {
        switch self {
        case .initialize: return "INITIALIZE"
        case .assembling: return "ASSEMBLING"
        case .poweringUp: return "POWERING UP"
        case .lockup: return nil
        }
    }
}

// MARK: - Splash

struct SplashView: View {
    let onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var scheme
    @State private var phase: SplashPhase = .initialize
    @State private var assemblyProgress: CGFloat = 0
    @State private var powerProgress: CGFloat = 0

    private let logoSize: CGFloat = 200

    var body: some View {
        ZStack {
            Color("SplashBackground")
                .ignoresSafeArea()

            GridBackdrop(accent: accent)
                .opacity(phase == .lockup ? 0.14 : 0.09)
                .ignoresSafeArea()

            RadialGradient(
                colors: [accent.opacity(scheme == .dark ? 0.5 : 0.28), .clear],
                center: .center,
                startRadius: 4,
                endRadius: logoSize * 0.95
            )
            .frame(width: logoSize * 2, height: logoSize * 2)
            .opacity(phase == .poweringUp ? Double(powerProgress) : (phase == .lockup ? 0.3 : 0))
            .blendMode(scheme == .dark ? .plusLighter : .normal)

            ScanRings(accent: accent, active: phase != .lockup)
                .frame(width: logoSize * 1.55, height: logoSize * 1.55)
                .opacity(phase == .lockup ? 0 : (phase == .initialize ? 0.55 : 0.85))

            LightBeam(accent: accent, progress: phase == .poweringUp ? powerProgress : 0)
                .frame(width: 6, height: logoSize * 1.35)
                .blendMode(scheme == .dark ? .plusLighter : .normal)

            VStack(spacing: 0) {
                SplashLogoStack(
                    phase: phase,
                    assemblyProgress: assemblyProgress,
                    powerProgress: powerProgress,
                    size: logoSize
                )

                Lockup()
                    .padding(.top, 28)
                    .opacity(phase == .lockup ? 1 : 0)
                    .offset(y: phase == .lockup ? 0 : 12)
            }
            .offset(y: phase == .lockup ? -16 : -8)

            VStack {
                Spacer()
                CaptionLabel(text: phase.caption, accent: accent)
                    .padding(.bottom, 64)
            }
        }
        .task { await run() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Gunpla Vault. Build. Collect. Remember.")
    }

    private var accent: Color { Color("SplashAccent") }

    @MainActor
    private func run() async {
        guard !reduceMotion else {
            phase = .lockup
            assemblyProgress = 1
            powerProgress = 1
            try? await Task.sleep(for: .milliseconds(600))
            onFinish()
            return
        }

        for next in SplashPhase.allCases.dropFirst() {
            try? await Task.sleep(for: phase.hold)

            if next == .assembling {
                assemblyProgress = 0
                withAnimation(next.transition) { phase = next }
                withAnimation(.easeInOut(duration: 0.65)) {
                    assemblyProgress = 1
                }
            } else if next == .poweringUp {
                powerProgress = 0
                withAnimation(next.transition) { phase = next }
                withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
                    powerProgress = 1
                }
            } else {
                withAnimation(next.transition) { phase = next }
            }
        }

        try? await Task.sleep(for: SplashPhase.lockup.hold)
        onFinish()
    }
}

// MARK: - Logo stack

private struct SplashLogoStack: View {
    let phase: SplashPhase
    let assemblyProgress: CGFloat
    let powerProgress: CGFloat
    let size: CGFloat

    private var accent: Color { Color("SplashAccent") }

    private var brandStage: BrandMarkStage {
        switch phase {
        case .initialize: return .wireframe
        case .assembling: return .assembling
        case .poweringUp, .lockup: return .poweringUp
        }
    }

    var body: some View {
        ZStack {
            if phase <= .assembling {
                BrandMarkView(
                    stage: brandStage,
                    size: size,
                    assemblyProgress: assemblyProgress,
                    showHexagon: false,
                    accentOverride: accent
                )
                .opacity(phase == .assembling ? 1 : 1)
                .scaleEffect(phase == .assembling ? 1 : 0.94)
            }

            if phase >= .poweringUp {
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.2237, style: .continuous))
                    .shadow(color: accent.opacity(0.35 * Double(powerProgress)), radius: 18, y: 4)
                    .opacity(Double(powerProgress))
                    .scaleEffect(logoScale)
            }
        }
        .frame(width: size, height: size)
        .animation(.easeInOut(duration: 0.45), value: phase)
    }

    private var logoScale: CGFloat {
        switch phase {
        case .poweringUp: return 0.94 + powerProgress * 0.06
        case .lockup: return 0.88
        default: return 1
        }
    }
}

// MARK: - Procedural elements

private struct ScanRings: View {
    let accent: Color
    let active: Bool

    var body: some View {
        TimelineView(.animation(paused: !active)) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let base = min(size.width, size.height) / 2

                for i in 0..<3 {
                    let radius = base * (0.58 + Double(i) * 0.15)
                    var ring = Path()
                    ring.addArc(
                        center: center,
                        radius: radius,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360),
                        clockwise: false
                    )

                    let dash: [CGFloat] = i == 1 ? [3, 8] : [radius * 1.2, radius * 0.85]
                    let spin = t * (i.isMultiple(of: 2) ? 12 : -18)

                    context.drawLayer { layer in
                        layer.translateBy(x: center.x, y: center.y)
                        layer.rotate(by: .degrees(spin))
                        layer.translateBy(x: -center.x, y: -center.y)
                        layer.stroke(
                            ring,
                            with: .color(accent.opacity(0.38 - Double(i) * 0.07)),
                            style: StrokeStyle(lineWidth: i == 1 ? 0.9 : 1.2, dash: dash)
                        )
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

private struct LightBeam: View {
    let accent: Color
    let progress: CGFloat

    var body: some View {
        LinearGradient(
            colors: [accent.opacity(0), accent.opacity(0.9), accent.opacity(0)],
            startPoint: .top,
            endPoint: .bottom
        )
        .blur(radius: 6)
        .scaleEffect(y: max(0.02, progress), anchor: .center)
        .opacity(Double(progress))
        .allowsHitTesting(false)
    }
}

private struct GridBackdrop: View {
    let accent: Color

    var body: some View {
        Canvas { context, size in
            let step: CGFloat = 32
            var grid = Path()
            var x: CGFloat = 0
            while x <= size.width {
                grid.move(to: CGPoint(x: x, y: 0))
                grid.addLine(to: CGPoint(x: x, y: size.height))
                x += step
            }
            var y: CGFloat = 0
            while y <= size.height {
                grid.move(to: CGPoint(x: 0, y: y))
                grid.addLine(to: CGPoint(x: size.width, y: y))
                y += step
            }
            context.stroke(grid, with: .color(accent.opacity(0.35)), lineWidth: 0.45)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Typography

private struct Lockup: View {
    var body: some View {
        VStack(spacing: 6) {
            Text("GUNPLA")
                .font(.system(size: 32, weight: .heavy))
                .tracking(10)
                .foregroundStyle(Color("SplashInk"))

            Text("VAULT")
                .font(.system(size: 20, weight: .semibold))
                .tracking(17)
                .foregroundStyle(Color("SplashAccent"))

            Text("Build. Collect. Remember.")
                .font(.system(size: 13, weight: .regular))
                .tracking(0.3)
                .foregroundStyle(Color("SplashInk").opacity(0.72))
                .padding(.top, 10)
        }
        .offset(x: 4)
    }
}

private struct CaptionLabel: View {
    let text: String?
    let accent: Color

    var body: some View {
        Text(text ?? " ")
            .font(.system(size: 11, weight: .semibold))
            .tracking(2.4)
            .foregroundStyle(accent)
            .opacity(text == nil ? 0 : 1)
            .animation(.easeInOut(duration: 0.25), value: text)
    }
}

// MARK: - Preview

#Preview("Light") {
    SplashView {}
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    SplashView {}
        .preferredColorScheme(.dark)
}
