import SwiftUI

enum BrandMarkStage: Equatable {
    case wireframe
    case assembling
    case poweringUp
    case complete
}

struct BrandMarkView: View {
    var stage: BrandMarkStage = .complete
    var size: CGFloat = 120
    var assemblyProgress: CGFloat = 1
    var showHexagon: Bool = true
    var accentOverride: Color?

    @Environment(\.colorScheme) private var colorScheme

    private var accent: Color { accentOverride ?? GVColors.accent }
    private var helmetFill: Color {
        colorScheme == .dark ? Color(red: 0.18, green: 0.19, blue: 0.24) : .white
    }
    private var helmetStroke: Color {
        colorScheme == .dark ? Color(white: 0.35) : Color(red: 0.78, green: 0.84, blue: 0.94)
    }
    private var eyeGlow: Double {
        switch stage {
        case .wireframe, .assembling: return 0
        case .poweringUp: return 0.55 + assemblyProgress * 0.45
        case .complete: return 1
        }
    }

    var body: some View {
        ZStack {
            if showHexagon {
                HexagonShape()
                    .stroke(accent, lineWidth: size * 0.035)
                    .frame(width: size, height: size)
                    .opacity(stage == .wireframe ? 0.55 : 1)
            }

            if stage == .assembling {
                helmetCore
                    .opacity(0.3)
                assemblingParts
            } else {
                helmetCore
            }

            if stage == .poweringUp || stage == .complete {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [accent.opacity(0.45), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: size * 0.55
                        )
                    )
                    .frame(width: size * 1.1, height: size * 0.35)
                    .offset(y: size * 0.42)
                    .opacity(stage == .poweringUp ? assemblyProgress : 0.85)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private var helmetCore: some View {
        ZStack {
            HelmetBodyShape()
                .fill(stage == .wireframe ? .clear : helmetFill)
                .overlay {
                    HelmetBodyShape()
                        .stroke(
                            stage == .wireframe ? accent.opacity(0.85) : helmetStroke,
                            lineWidth: stage == .wireframe ? 1.4 : 1
                        )
                }

            HelmetVisorShape()
                .fill(stage == .wireframe ? .clear : (colorScheme == .dark ? Color(white: 0.12) : Color(red: 0.12, green: 0.16, blue: 0.28)))
                .overlay {
                    if stage == .wireframe {
                        HelmetVisorShape()
                            .stroke(accent.opacity(0.75), lineWidth: 1.2)
                    }
                }
                .frame(width: size * 0.52, height: size * 0.22)
                .offset(y: size * 0.02)

            HStack(spacing: size * 0.14) {
                eye
                eye
            }
            .offset(y: size * 0.02)

            VFinShape()
                .fill(stage == .wireframe ? .clear : accent.opacity(0.95))
                .overlay {
                    if stage == .wireframe {
                        VFinShape()
                            .stroke(accent.opacity(0.8), lineWidth: 1.2)
                    }
                }
                .frame(width: size * 0.22, height: size * 0.18)
                .offset(y: -size * 0.28)
        }
        .frame(width: size * 0.62, height: size * 0.62)
    }

    private var eye: some View {
        Capsule()
            .fill(accent)
            .frame(width: size * 0.1, height: size * 0.045)
            .shadow(color: accent.opacity(eyeGlow), radius: size * 0.06)
            .opacity(stage == .wireframe ? 0.35 : max(0.2, eyeGlow))
    }

    private var assemblingParts: some View {
        ZStack {
            assemblyPart(HelmetCrestPart(), offset: partOffset(index: 0))
            assemblyPart(HelmetCheekPart(side: .left), offset: partOffset(index: 1))
            assemblyPart(HelmetCheekPart(side: .right), offset: partOffset(index: 2))
            assemblyPart(HelmetChinPart(), offset: partOffset(index: 3))
            assemblyPart(HelmetVisorPart(), offset: partOffset(index: 4))
        }
        .frame(width: size * 0.62, height: size * 0.62)
    }

    private func partOffset(index: Int) -> CGSize {
        let spread = size * 0.38 * (1 - assemblyProgress)
        let angles: [Double] = [-90, 150, 30, 180, 0]
        let radians = angles[index % angles.count] * .pi / 180
        return CGSize(
            width: cos(radians) * spread,
            height: sin(radians) * spread
        )
    }

    private func assemblyPart<S: Shape>(_ shape: S, offset: CGSize) -> some View {
        let opacity = 0.35 + assemblyProgress * 0.65
        return shape
            .fill(helmetFill)
            .overlay(shape.stroke(accent.opacity(0.65), lineWidth: 1.2))
            .frame(width: size * 0.62, height: size * 0.62)
            .offset(offset)
            .opacity(opacity)
    }
}

// MARK: - Shapes

private struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        for i in 0..<6 {
            let angle = CGFloat(i) * .pi / 3 - .pi / 6
            let point = CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            )
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}

private struct HelmetBodyShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: w * 0.5, y: h * 0.06))
        path.addLine(to: CGPoint(x: w * 0.88, y: h * 0.38))
        path.addLine(to: CGPoint(x: w * 0.82, y: h * 0.88))
        path.addLine(to: CGPoint(x: w * 0.18, y: h * 0.88))
        path.addLine(to: CGPoint(x: w * 0.12, y: h * 0.38))
        path.closeSubpath()
        return path
    }
}

private struct HelmetVisorShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path(roundedRect: rect, cornerRadius: rect.height * 0.35)
    }
}

private struct VFinShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY * 0.55))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private enum CheekSide { case left, right }

private struct HelmetCheekPart: Shape {
    let side: CheekSide

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let inset: CGFloat = side == .left ? 0.08 : 0.52
        let cheek = CGRect(x: rect.width * inset, y: rect.height * 0.42, width: rect.width * 0.28, height: rect.height * 0.28)
        path.addRoundedRect(in: cheek, cornerSize: CGSize(width: 8, height: 8))
        return path
    }
}

private struct HelmetCrestPart: Shape {
    func path(in rect: CGRect) -> Path {
        VFinShape().path(in: CGRect(x: rect.width * 0.39, y: rect.height * 0.02, width: rect.width * 0.22, height: rect.height * 0.22))
    }
}

private struct HelmetChinPart: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRoundedRect(
            in: CGRect(x: rect.width * 0.28, y: rect.height * 0.72, width: rect.width * 0.44, height: rect.height * 0.18),
            cornerSize: CGSize(width: 6, height: 6)
        )
        return path
    }
}

private struct HelmetVisorPart: Shape {
    func path(in rect: CGRect) -> Path {
        HelmetVisorShape().path(
            in: CGRect(x: rect.width * 0.24, y: rect.height * 0.34, width: rect.width * 0.52, height: rect.height * 0.2)
        )
    }
}

#Preview("Stages") {
    VStack(spacing: 24) {
        HStack(spacing: 20) {
            BrandMarkView(stage: .wireframe, size: 80)
            BrandMarkView(stage: .assembling, size: 80, assemblyProgress: 0.5)
        }
        HStack(spacing: 20) {
            BrandMarkView(stage: .poweringUp, size: 80, assemblyProgress: 0.8)
            BrandMarkView(stage: .complete, size: 80)
        }
    }
    .padding()
    .background(GVColors.background)
}
