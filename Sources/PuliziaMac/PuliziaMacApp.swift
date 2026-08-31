import SwiftUI

@main
struct PuliziaMacApp: App {
    @StateObject private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 820, minHeight: 560)
                .environmentObject(settings)
                .tint(settings.accentTheme.color)
                .preferredColorScheme(settings.colorSchemePreference.colorScheme)
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
