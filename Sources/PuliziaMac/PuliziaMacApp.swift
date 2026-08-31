import SwiftUI

@main
struct PuliziaMacApp: App {
    @StateObject private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            // L'aspetto (chiaro/scuro/sistema) è gestito da ContentView tramite
            // NSApp.appearance, non da .preferredColorScheme(): su macOS le due
            // meccaniche possono entrare in conflitto e "System" può restare bloccato
            // sull'ultimo aspetto forzato invece di tornare a seguire il sistema.
            ContentView()
                .frame(minWidth: 820, minHeight: 560)
                .environmentObject(settings)
                .tint(settings.accentTheme.color)
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
