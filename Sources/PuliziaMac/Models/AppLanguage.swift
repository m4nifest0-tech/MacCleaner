import Foundation

enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case italian = "it"
    case english = "en"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .italian: return "Italiano"
        case .english: return "English"
        }
    }

    /// Letta direttamente da UserDefaults (stessa chiave di `AppSettings`), per i pochi
    /// messaggi generati nel layer di servizio che non ha accesso all'ambiente SwiftUI.
    static var current: AppLanguage {
        UserDefaults.standard.string(forKey: "appLanguage").flatMap(AppLanguage.init(rawValue:)) ?? .italian
    }
}
