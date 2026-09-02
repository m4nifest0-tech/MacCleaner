import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var nav: NavigationState

    private var selection: Binding<AppSection?> {
        Binding(get: { nav.selection }, set: { nav.selection = $0 })
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: selection)
        } detail: {
            switch nav.selection {
            case .dashboard:
                DashboardView(selection: selection)
            case .smartClean:
                SmartCleanView()
            case .cacheCleaner:
                CacheCleanerView()
            case .archScanner:
                ArchScannerView()
            case .duplicateFinder:
                DuplicateFinderView()
            case .largeFiles:
                LargeFilesView()
            case .diskExplorer:
                DiskExplorerView()
            case .mailAttachments:
                MailAttachmentsView()
            case .uninstaller:
                UninstallerView()
            case .loginItems:
                LoginItemsView()
            case .updateManager:
                UpdateManagerView()
            case .settings:
                SettingsView()
            case nil:
                ContentUnavailableView(settings.t("content.select_section"), systemImage: "sidebar.left")
            }
        }
        .onAppear {
            applyAppearance(settings.colorSchemePreference)
            applyDockVisibility(settings.hideDockIcon)
        }
        .onChange(of: settings.colorSchemePreference) { _, newValue in applyAppearance(newValue) }
        .onChange(of: settings.hideDockIcon) { _, newValue in applyDockVisibility(newValue) }
    }

    /// `.accessory` nasconde l'icona dal Dock (e dal Cmd+Tab) mantenendo l'app attiva
    /// tramite la barra dei menù; `.regular` la ripristina come app normale.
    private func applyDockVisibility(_ hidden: Bool) {
        NSApp.setActivationPolicy(hidden ? .accessory : .regular)
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
