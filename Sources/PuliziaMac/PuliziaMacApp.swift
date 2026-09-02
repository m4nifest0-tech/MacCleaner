import SwiftUI

@main
struct PuliziaMacApp: App {
    @StateObject private var settings = AppSettings()
    @StateObject private var stats = StatsStore()
    @StateObject private var exclusions = ExclusionStore()
    @StateObject private var nav = NavigationState()

    var body: some Scene {
        // `Window` (non `WindowGroup`) gestisce una singola istanza: quando l'icona
        // Dock è nascosta e si riapre dalla barra dei menù, `openWindow(id:)` riporta
        // in primo piano la finestra esistente invece di aprirne una seconda.
        Window("PuliziaMac", id: "main") {
            // L'aspetto (chiaro/scuro/sistema) è gestito da ContentView tramite
            // NSApp.appearance, non da .preferredColorScheme(): su macOS le due
            // meccaniche possono entrare in conflitto e "System" può restare bloccato
            // sull'ultimo aspetto forzato invece di tornare a seguire il sistema.
            ContentView()
                .frame(minWidth: 1000, idealWidth: 1280, minHeight: 650, idealHeight: 820)
                .environmentObject(settings)
                .environmentObject(stats)
                .environmentObject(exclusions)
                .environmentObject(nav)
                .tint(settings.accentTheme.color)
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandMenu(settings.t("menu.goto")) {
                ForEach(AppSection.allCases) { section in
                    gotoButton(section)
                }
            }
        }

        // Icona nella barra dei menù: accesso rapido a spazio libero/liberato e alla
        // finestra principale senza doverla tenere aperta o in primo piano.
        MenuBarExtra("PuliziaMac", systemImage: "wand.and.sparkles") {
            MenuBarContentView()
                .environmentObject(settings)
                .environmentObject(stats)
                .environmentObject(nav)
        }
        .menuBarExtraStyle(.window)
    }

    /// Cmd+1…Cmd+9 per le prime nove sezioni della sidebar, Cmd+, per Impostazioni
    /// (convenzione standard su macOS), nessuna scorciatoia per le restanti.
    @ViewBuilder
    private func gotoButton(_ section: AppSection) -> some View {
        let button = Button(settings.t(section.titleKey)) { nav.selection = section }
        if section == .settings {
            button.keyboardShortcut(",", modifiers: .command)
        } else if let key = section.keyboardShortcutKey {
            button.keyboardShortcut(KeyEquivalent(key), modifiers: .command)
        } else {
            button
        }
    }
}
