import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        Form {
            Section(settings.t("settings.language_header")) {
                Picker(settings.t("settings.language_header"), selection: $settings.language) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            Section(settings.t("settings.appearance_header")) {
                Picker(settings.t("settings.appearance_header"), selection: $settings.colorSchemePreference) {
                    Text(settings.t("settings.appearance_system")).tag(ColorSchemePreference.system)
                    Text(settings.t("settings.appearance_light")).tag(ColorSchemePreference.light)
                    Text(settings.t("settings.appearance_dark")).tag(ColorSchemePreference.dark)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            Section(settings.t("settings.accent_header")) {
                accentColorGrid
            }
        }
        .formStyle(.grouped)
        .navigationTitle(settings.t(AppSection.settings.titleKey))
    }

    private var accentColorGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 16) {
            ForEach(AccentTheme.allCases) { theme in
                accentSwatch(theme)
            }
        }
        .padding(.vertical, 4)
    }

    private func accentSwatch(_ theme: AccentTheme) -> some View {
        let isSelected = settings.accentTheme == theme
        return Button {
            settings.accentTheme = theme
        } label: {
            VStack(spacing: 6) {
                Circle()
                    .fill(theme.color)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.primary, lineWidth: isSelected ? 2 : 0)
                            .padding(-3)
                    )
                    .overlay {
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                        }
                    }
                Text(settings.t(theme.displayNameKey))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}
