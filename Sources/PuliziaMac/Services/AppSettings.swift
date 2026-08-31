import SwiftUI

/// Stato condiviso di lingua e tema, iniettato come `@EnvironmentObject` alla radice
/// dell'app: ogni view osserva questo oggetto, quindi cambiare lingua o tema aggiorna
/// tutta l'interfaccia immediatamente, senza riavviare l'app.
final class AppSettings: ObservableObject {
    @Published var language: AppLanguage {
        didSet { defaults.set(language.rawValue, forKey: Keys.language) }
    }
    @Published var colorSchemePreference: ColorSchemePreference {
        didSet { defaults.set(colorSchemePreference.rawValue, forKey: Keys.colorScheme) }
    }
    @Published var accentTheme: AccentTheme {
        didSet { defaults.set(accentTheme.rawValue, forKey: Keys.accentTheme) }
    }

    private let defaults: UserDefaults

    private enum Keys {
        static let language = "appLanguage"
        static let colorScheme = "appColorScheme"
        static let accentTheme = "appAccentTheme"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        language = defaults.string(forKey: Keys.language).flatMap(AppLanguage.init(rawValue:)) ?? .italian
        colorSchemePreference = defaults.string(forKey: Keys.colorScheme).flatMap(ColorSchemePreference.init(rawValue:)) ?? .system
        accentTheme = defaults.string(forKey: Keys.accentTheme).flatMap(AccentTheme.init(rawValue:)) ?? .blue
    }

    func t(_ key: String) -> String {
        Localization.string(key, language: language)
    }
}
