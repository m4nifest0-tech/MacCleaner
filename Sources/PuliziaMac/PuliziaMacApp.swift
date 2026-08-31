import SwiftUI

@main
struct PuliziaMacApp: App {
    @StateObject private var settings = AppSettings()
    @StateObject private var stats = StatsStore()
    @StateObject private var exclusions = ExclusionStore()

    var body: some Scene {
        WindowGroup {
            // L'aspetto (chiaro/scuro/sistema) è gestito da ContentView tramite
            // NSApp.appearance, non da .preferredColorScheme(): su macOS le due
            // meccaniche possono entrare in conflitto e "System" può restare bloccato
            // sull'ultimo aspetto forzato invece di tornare a seguire il sistema.
            ContentView()
                .frame(minWidth: 1000, idealWidth: 1280, minHeight: 650, idealHeight: 820)
                .environmentObject(settings)
                .environmentObject(stats)
                .environmentObject(exclusions)
                .tint(settings.accentTheme.color)
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
