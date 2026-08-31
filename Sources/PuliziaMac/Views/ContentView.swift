import SwiftUI

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
    }
}
