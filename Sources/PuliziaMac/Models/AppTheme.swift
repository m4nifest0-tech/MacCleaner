import SwiftUI

enum ColorSchemePreference: String, CaseIterable, Identifiable, Codable {
    case system
    case light
    case dark

    var id: String { rawValue }

    /// nil lascia decidere al sistema (segue Chiaro/Scuro di macOS).
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum AccentTheme: String, CaseIterable, Identifiable, Codable {
    case blue
    case orange
    case purple
    case green
    case pink
    case red
    case teal
    case graphite

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .blue: return .blue
        case .orange: return .orange
        case .purple: return .purple
        case .green: return .green
        case .pink: return .pink
        case .red: return .red
        case .teal: return .teal
        case .graphite: return Color(red: 0.42, green: 0.44, blue: 0.47)
        }
    }

    var displayNameKey: String { "theme.accent.\(rawValue)" }
}
