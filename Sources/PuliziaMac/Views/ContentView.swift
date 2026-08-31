import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var selection: AppSection? = .cacheCleaner

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection)
        } detail: {
            switch selection {
            case .cacheCleaner:
                CacheCleanerView()
            case .archScanner:
                ArchScannerView()
            case .duplicateFinder:
                DuplicateFinderView()
            case .uninstaller:
                UninstallerView()
            case .updateManager:
                UpdateManagerView()
            case .settings:
                SettingsView()
            case nil:
                ContentUnavailableView(settings.t("content.select_section"), systemImage: "sidebar.left")
            }
        }
        .onAppear { applyAppearance(settings.colorSchemePreference) }
        .onChange(of: settings.colorSchemePreference) { _, newValue in applyAppearance(newValue) }
    }

    /// `.preferredColorScheme()` da solo non è affidabile su macOS per aggiornare
    /// l'aspetto di una finestra già mostrata: impostiamo direttamente l'aspetto
    /// dell'applicazione a livello AppKit, che è il modo con cui macOS applica davvero
    /// chiaro/scuro/sistema in tempo reale.
    private func applyAppearance(_ preference: ColorSchemePreference) {
        switch preference {
        case .system: NSApp.appearance = nil
        case .light: NSApp.appearance = NSAppearance(named: .aqua)
        case .dark: NSApp.appearance = NSAppearance(named: .darkAqua)
        }
    }
}
