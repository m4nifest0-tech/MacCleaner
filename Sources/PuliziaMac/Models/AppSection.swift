import Foundation

enum AppSection: String, CaseIterable, Identifiable, Hashable {
    case cacheCleaner
    case archScanner
    case duplicateFinder
    case uninstaller
    case updateManager
    case settings

    var id: String { rawValue }

    /// Chiave nel dizionario di localizzazione: vedi `Localization.swift`.
    var titleKey: String {
        switch self {
        case .cacheCleaner: return "sidebar.cacheCleaner"
        case .archScanner: return "sidebar.archScanner"
        case .duplicateFinder: return "sidebar.duplicateFinder"
        case .uninstaller: return "sidebar.uninstaller"
        case .updateManager: return "sidebar.updateManager"
        case .settings: return "sidebar.settings"
        }
    }

    var systemImage: String {
        switch self {
        case .cacheCleaner: return "trash.circle"
        case .archScanner: return "cpu"
        case .duplicateFinder: return "doc.on.doc"
        case .uninstaller: return "minus.circle"
        case .updateManager: return "arrow.triangle.2.circlepath.circle"
        case .settings: return "gearshape"
        }
    }
}
