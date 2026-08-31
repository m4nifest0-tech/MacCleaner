import SwiftUI
import AppKit

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var exclusions: ExclusionStore

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

            Section(settings.t("settings.exclusions_header")) {
                exclusionsList
            }
        }
        .formStyle(.grouped)
        .navigationTitle(settings.t(AppSection.settings.titleKey))
    }

    private var exclusionsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(settings.t("settings.exclusions_explanation"))
                .font(.caption)
                .foregroundStyle(.secondary)

            if exclusions.excludedFolders.isEmpty {
                Text(settings.t("settings.exclusions_empty"))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(exclusions.excludedFolders, id: \.self) { folder in
                    HStack {
                        Image(systemName: "folder")
                            .foregroundStyle(.secondary)
                        Text(folder.path)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                        Button {
                            exclusions.remove(folder)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }

            Button {
                addExcludedFolder()
            } label: {
                Label(settings.t("dup.add_folder"), systemImage: "plus")
            }
        }
    }

    private func addExcludedFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            exclusions.add(url)
        }
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
