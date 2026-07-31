import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

@MainActor
final class ThemeManager: ObservableObject {
    @Published var theme: AppTheme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: Self.storageKey) }
    }

    private static let storageKey = "gv.appTheme"

    init() {
        let stored = UserDefaults.standard.string(forKey: Self.storageKey) ?? AppTheme.system.rawValue
        theme = AppTheme(rawValue: stored) ?? .system
    }

    var colorScheme: ColorScheme? {
        switch theme {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum GVColors {
    static let accentLight = Color(red: 0.22, green: 0.47, blue: 0.96)
    static let accentDark = Color(red: 0.58, green: 0.38, blue: 0.98)

    static var accent: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.58, green: 0.38, blue: 0.98, alpha: 1)
                : UIColor(red: 0.22, green: 0.47, blue: 0.96, alpha: 1)
        })
    }

    static var background: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.06, green: 0.07, blue: 0.10, alpha: 1)
                : UIColor(red: 0.97, green: 0.97, blue: 0.98, alpha: 1)
        })
    }

    static var surface: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.11, green: 0.12, blue: 0.16, alpha: 1)
                : UIColor.white
        })
    }

    static var surfaceSecondary: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.15, green: 0.16, blue: 0.21, alpha: 1)
                : UIColor(red: 0.94, green: 0.95, blue: 0.97, alpha: 1)
        })
    }

    static var textPrimary: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? .white : UIColor(red: 0.08, green: 0.09, blue: 0.12, alpha: 1)
        })
    }

    static var textSecondary: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(white: 0.72, alpha: 1)
                : UIColor(red: 0.42, green: 0.45, blue: 0.52, alpha: 1)
        })
    }

    static var border: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(white: 0.22, alpha: 1)
                : UIColor(red: 0.88, green: 0.90, blue: 0.93, alpha: 1)
        })
    }

    static var success = Color(red: 0.18, green: 0.78, blue: 0.55)
    static var warning = Color(red: 0.98, green: 0.72, blue: 0.22)
}

enum GVTypography {
    static let largeTitle = Font.system(.largeTitle, design: .rounded, weight: .bold)
    static let title = Font.system(.title2, design: .rounded, weight: .bold)
    static let title2 = Font.system(.title3, design: .rounded, weight: .semibold)
    static let headline = Font.system(.headline, design: .rounded, weight: .semibold)
    static let body = Font.system(.body, design: .default)
    static let callout = Font.system(.callout, design: .default)
    static let caption = Font.system(.caption, design: .default, weight: .medium)
    static let tabLabel = Font.system(.caption2, design: .rounded, weight: .semibold)
}

struct GVCapsuleBadge: View {
    let text: String
    var tint: Color = GVColors.accent

    var body: some View {
        Text(text.uppercased())
            .font(GVTypography.caption)
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(tint.opacity(0.15), in: Capsule())
    }
}

struct GVPrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                }
                Text(title)
                    .font(GVTypography.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(.white)
            .background(GVColors.accent.opacity(isDisabled ? 0.4 : 1), in: RoundedRectangle(cornerRadius: 14))
        }
        .disabled(isDisabled || isLoading)
        .accessibilityHint(isLoading ? "Loading" : "")
    }
}

struct GVCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .background(GVColors.surface, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(GVColors.border, lineWidth: 1)
            )
    }
}

struct GVTextField: View {
    let title: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(GVTypography.caption)
                .foregroundStyle(GVColors.textSecondary)
            TextField(title, text: $text)
                .textContentType(textContentType)
                .keyboardType(keyboardType)
                .autocorrectionDisabled()
                .textInputAutocapitalization(keyboardType == .emailAddress ? .never : .words)
                .padding(14)
                .background(GVColors.surfaceSecondary, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(GVColors.border, lineWidth: 1)
                )
        }
    }
}

struct ScreenHeader: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(GVTypography.largeTitle)
                .foregroundStyle(GVColors.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(GVTypography.callout)
                    .foregroundStyle(GVColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct StatusBadge: View {
    let status: CollectionStatus

    var tint: Color {
        switch status {
        case .backlog: return GVColors.textSecondary
        case .inProgress: return GVColors.accent
        case .completed: return GVColors.success
        }
    }

    var body: some View {
        GVCapsuleBadge(text: status.displayName, tint: tint)
    }
}
