import SwiftUI

struct ConfigurationView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var profileStore: ProfileStore
    @EnvironmentObject private var collectionStore: CollectionStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                appearanceSection
                dataSyncSection
                aboutSection
            }
            .padding(20)
        }
        .background(GVColors.background)
        .navigationTitle("Configuration")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var appearanceSection: some View {
        SettingsSection(title: "Appearance") {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Theme")
                        .font(GVTypography.callout)
                        .foregroundStyle(GVColors.textPrimary)
                    Picker("Theme", selection: $themeManager.theme) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.label).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel("App theme")
                }

                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    Text("Accent Color")
                        .font(GVTypography.callout)
                        .foregroundStyle(GVColors.textPrimary)
                    HStack(spacing: 14) {
                        ForEach(AccentPalette.allCases) { palette in
                            accentSwatch(palette)
                        }
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    Text("App Icon")
                        .font(GVTypography.callout)
                        .foregroundStyle(GVColors.textPrimary)
                    HStack(spacing: 12) {
                        appIconOption(.default, enabled: true)
                        appIconOption(.classic, enabled: false)
                    }
                }

                Divider()

                SettingsToggleRow(
                    title: "Use System Settings",
                    subtitle: "Match device light/dark appearance",
                    isOn: $themeManager.followSystemSettings
                )
            }
        }
    }

    private var dataSyncSection: some View {
        SettingsSection(title: "Data & Sync") {
            VStack(spacing: 0) {
                SettingsToggleRow(
                    title: "Cloud Sync",
                    subtitle: cloudSyncSubtitle,
                    isOn: $themeManager.cloudSyncEnabled
                )
                .disabled(!collectionStore.isCloudSyncEnabled && profileStore.tier != .pro)

                if profileStore.tier == .pro {
                    Divider()
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Auto Backup")
                                .font(GVTypography.callout)
                                .foregroundStyle(GVColors.textPrimary)
                            Text("Sync collection on schedule")
                                .font(GVTypography.caption)
                                .foregroundStyle(GVColors.textSecondary)
                        }
                        Spacer()
                        Picker("Auto Backup", selection: $themeManager.autoBackup) {
                            ForEach(AutoBackupFrequency.allCases) { option in
                                Text(option.label).tag(option)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                    }
                    .padding(.vertical, 10)
                }
            }
        }
    }

    private var aboutSection: some View {
        SettingsSection(title: "About") {
            VStack(spacing: 16) {
                VStack(spacing: 10) {
                    AppLogoView(stage: .complete, size: 72)
                    Text("GUNPLA VAULT")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(GVColors.textPrimary)
                    Text("Build. Collect. Remember.")
                        .font(GVTypography.caption)
                        .foregroundStyle(GVColors.textSecondary)
                    Text(versionString)
                        .font(GVTypography.caption)
                        .foregroundStyle(GVColors.textSecondary)
                }
                .frame(maxWidth: .infinity)

                Divider()

                NavigationLink {
                    LegalDocumentView(document: .privacy)
                } label: {
                    NavRow(title: "Privacy Policy", icon: "hand.raised.fill")
                }
                Divider()
                NavigationLink {
                    LegalDocumentView(document: .terms)
                } label: {
                    NavRow(title: "Terms of Use", icon: "doc.text.fill")
                }
            }
        }
    }

    private var cloudSyncSubtitle: String {
        if profileStore.tier != .pro {
            return "Available with Pro membership"
        }
        if collectionStore.isCloudSyncEnabled {
            return "Supabase cloud sync for Pro"
        }
        return "Configure Supabase to enable sync"
    }

    private var versionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }

    private func accentSwatch(_ palette: AccentPalette) -> some View {
        Button {
            themeManager.accentPalette = palette
        } label: {
            Circle()
                .fill(palette.gradient)
                .frame(width: 32, height: 32)
                .overlay {
                    if themeManager.accentPalette == palette {
                        Circle()
                            .strokeBorder(.white, lineWidth: 2)
                            .padding(2)
                        Image(systemName: "checkmark")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                    }
                }
                .shadow(color: palette.color.opacity(0.3), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(palette.label) accent color")
        .accessibilityAddTraits(themeManager.accentPalette == palette ? .isSelected : [])
    }

    @ViewBuilder
    private func appIconOption(_ style: AppIconStyle, enabled: Bool) -> some View {
        let isSelected = themeManager.appIconStyle == style
        Button {
            guard enabled else { return }
            themeManager.appIconStyle = style
        } label: {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(GVColors.surfaceSecondary)
                    .frame(width: 64, height: 64)
                    .overlay {
                        AppLogoView(stage: .complete, size: 44)
                            .opacity(enabled ? 1 : 0.45)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(isSelected ? themeManager.accentColor : GVColors.border, lineWidth: isSelected ? 2 : 1)
                    }
                Text(style.label)
                    .font(GVTypography.caption)
                    .foregroundStyle(enabled ? GVColors.textPrimary : GVColors.textSecondary)
                if !enabled {
                    Text("Soon")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(GVColors.textSecondary)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

#Preview {
    NavigationStack {
        ConfigurationView()
            .environmentObject(ThemeManager())
            .environmentObject(ProfileStore())
            .environmentObject(CollectionStore(context: PersistenceController.shared.mainContext, profileStore: ProfileStore()))
    }
}
