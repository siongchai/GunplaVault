import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case light
    case dark
    case system

    var id: String { rawValue }

    var label: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }
}

enum AccentPalette: String, CaseIterable, Identifiable {
    case violet
    case blue
    case pink
    case orange
    case green

    var id: String { rawValue }

    var label: String {
        rawValue.capitalized
    }

    var color: Color {
        switch self {
        case .violet: return Color(red: 0.45, green: 0.35, blue: 0.98)
        case .blue: return Color(red: 0.22, green: 0.47, blue: 0.96)
        case .pink: return Color(red: 0.93, green: 0.32, blue: 0.58)
        case .orange: return Color(red: 0.98, green: 0.55, blue: 0.18)
        case .green: return Color(red: 0.18, green: 0.78, blue: 0.55)
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .violet:
            return LinearGradient(
                colors: [Color(red: 0.22, green: 0.47, blue: 0.96), Color(red: 0.58, green: 0.38, blue: 0.98)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .blue:
            return LinearGradient(
                colors: [Color(red: 0.18, green: 0.55, blue: 0.98), Color(red: 0.22, green: 0.72, blue: 0.92)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .pink:
            return LinearGradient(
                colors: [Color(red: 0.98, green: 0.35, blue: 0.55), Color(red: 0.75, green: 0.28, blue: 0.92)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .orange:
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.62, blue: 0.22), Color(red: 0.98, green: 0.35, blue: 0.28)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .green:
            return LinearGradient(
                colors: [Color(red: 0.18, green: 0.78, blue: 0.55), Color(red: 0.12, green: 0.62, blue: 0.72)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

enum AutoBackupFrequency: String, CaseIterable, Identifiable {
    case off
    case daily
    case weekly

    var id: String { rawValue }

    var label: String {
        switch self {
        case .off: return "Off"
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        }
    }
}

enum AppIconStyle: String, CaseIterable, Identifiable {
    case `default`
    case classic

    var id: String { rawValue }

    var label: String {
        switch self {
        case .default: return "Default"
        case .classic: return "Classic"
        }
    }
}

@MainActor
final class ThemeManager: ObservableObject {
    @Published var theme: AppTheme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: Self.themeKey) }
    }

    @Published var accentPalette: AccentPalette {
        didSet { UserDefaults.standard.set(accentPalette.rawValue, forKey: Self.accentKey) }
    }

    @Published var followSystemSettings: Bool {
        didSet { UserDefaults.standard.set(followSystemSettings, forKey: Self.followSystemKey) }
    }

    @Published var cloudSyncEnabled: Bool {
        didSet { UserDefaults.standard.set(cloudSyncEnabled, forKey: Self.cloudSyncKey) }
    }

    @Published var autoBackup: AutoBackupFrequency {
        didSet { UserDefaults.standard.set(autoBackup.rawValue, forKey: Self.autoBackupKey) }
    }

    @Published var appIconStyle: AppIconStyle {
        didSet { UserDefaults.standard.set(appIconStyle.rawValue, forKey: Self.appIconKey) }
    }

    private static let themeKey = "gv.appTheme"
    private static let accentKey = "gv.accentPalette"
    private static let followSystemKey = "gv.followSystemSettings"
    private static let cloudSyncKey = "gv.cloudSyncEnabled"
    private static let autoBackupKey = "gv.autoBackup"
    private static let appIconKey = "gv.appIconStyle"

    init() {
        let defaults = UserDefaults.standard
        theme = AppTheme(rawValue: defaults.string(forKey: Self.themeKey) ?? AppTheme.system.rawValue) ?? .system
        accentPalette = AccentPalette(rawValue: defaults.string(forKey: Self.accentKey) ?? AccentPalette.violet.rawValue) ?? .violet
        followSystemSettings = defaults.object(forKey: Self.followSystemKey) as? Bool ?? true
        cloudSyncEnabled = defaults.object(forKey: Self.cloudSyncKey) as? Bool ?? true
        autoBackup = AutoBackupFrequency(rawValue: defaults.string(forKey: Self.autoBackupKey) ?? AutoBackupFrequency.daily.rawValue) ?? .daily
        appIconStyle = AppIconStyle(rawValue: defaults.string(forKey: Self.appIconKey) ?? AppIconStyle.default.rawValue) ?? .default
    }

    var accentColor: Color { accentPalette.color }

    var accentGradient: LinearGradient { accentPalette.gradient }

    var colorScheme: ColorScheme? {
        if followSystemSettings || theme == .system { return nil }
        switch theme {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }

    static var isCloudSyncEnabled: Bool {
        UserDefaults.standard.object(forKey: cloudSyncKey) as? Bool ?? true
    }
}

enum GVColors {
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
                ? UIColor(red: 0.05, green: 0.06, blue: 0.09, alpha: 1)
                : UIColor(red: 0.95, green: 0.96, blue: 0.98, alpha: 1)
        })
    }

    static var surface: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.10, green: 0.11, blue: 0.15, alpha: 1)
                : UIColor.white
        })
    }

    static var surfaceSecondary: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.14, green: 0.15, blue: 0.20, alpha: 1)
                : UIColor(red: 0.93, green: 0.94, blue: 0.97, alpha: 1)
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
                ? UIColor(white: 0.68, alpha: 1)
                : UIColor(red: 0.42, green: 0.45, blue: 0.52, alpha: 1)
        })
    }

    static var border: Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(white: 0.20, alpha: 1)
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
    static let metric = Font.system(.title, design: .rounded, weight: .bold)
}

struct GVCapsuleBadge: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let text: String
    var tint: Color?

    private var resolvedTint: Color { tint ?? themeManager.accentColor }

    var body: some View {
        Text(text.uppercased())
            .font(GVTypography.caption)
            .foregroundStyle(resolvedTint)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(resolvedTint.opacity(0.14), in: Capsule())
    }
}

struct GVPrimaryButton: View {
    @EnvironmentObject private var themeManager: ThemeManager

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
            .background(
                themeManager.accentGradient.opacity(isDisabled ? 0.4 : 1),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
        }
        .disabled(isDisabled || isLoading)
        .accessibilityHint(isLoading ? "Loading" : "")
    }
}

struct GVCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .background(GVColors.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(GVColors.border, lineWidth: 1)
            )
            .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.04), radius: 8, y: 2)
    }
}

struct GVGradientCard<Content: View>: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(themeManager.accentGradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: themeManager.accentColor.opacity(0.25), radius: 12, y: 6)
    }
}

struct GVProgressBar: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let progress: Double
    var height: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(GVColors.surfaceSecondary)
                Capsule()
                    .fill(themeManager.accentGradient)
                    .frame(width: max(0, geo.size.width * min(max(progress, 0), 1)))
            }
        }
        .frame(height: height)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(progress * 100)) percent")
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
                .background(GVColors.surfaceSecondary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
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
                .accessibilityAddTraits(.isHeader)
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
    @EnvironmentObject private var themeManager: ThemeManager

    let status: CollectionStatus

    var tint: Color {
        switch status {
        case .backlog: return GVColors.textSecondary
        case .inProgress: return themeManager.accentColor
        case .completed: return GVColors.success
        }
    }

    var body: some View {
        GVCapsuleBadge(text: status.displayName, tint: tint)
    }
}

struct FilterChip: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(GVTypography.caption)
                .foregroundStyle(isSelected ? .white : GVColors.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background {
                    if isSelected {
                        Capsule().fill(themeManager.accentGradient)
                    } else {
                        Capsule().fill(GVColors.surfaceSecondary)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(GVTypography.caption)
                .foregroundStyle(GVColors.textSecondary)
                .padding(.leading, 4)

            GVCard {
                VStack(spacing: 0) {
                    content
                }
            }
        }
    }
}

struct SettingsToggleRow: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let title: String
    var subtitle: String?
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(GVTypography.callout)
                    .foregroundStyle(GVColors.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(GVTypography.caption)
                        .foregroundStyle(GVColors.textSecondary)
                }
            }
        }
        .tint(themeManager.accentColor)
        .padding(.vertical, 10)
    }
}

struct ProfileAvatarView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    var name: String
    var size: CGFloat = 40

    private var initials: String {
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first.map(String.init) }
        return letters.isEmpty ? "G" : letters.joined()
    }

    var body: some View {
        Circle()
            .fill(themeManager.accentGradient)
            .frame(width: size, height: size)
            .overlay {
                Text(initials.uppercased())
                    .font(.system(size: size * 0.34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .accessibilityLabel("Profile photo for \(name)")
    }
}

extension View {
    func minTapTarget() -> some View {
        frame(minWidth: 44, minHeight: 44)
    }
}
