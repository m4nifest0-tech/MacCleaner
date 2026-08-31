import Foundation

enum AppSection: String, CaseIterable, Identifiable, Hashable {
    case dashboard
    case smartClean
    case cacheCleaner
    case archScanner
    case duplicateFinder
    case largeFiles
    case uninstaller
    case loginItems
    case updateManager
    case settings

    var id: String { rawValue }

    /// Chiave nel dizionario di localizzazione: vedi `Localization.swift`.
    var titleKey: String {
        switch self {
        case .dashboard: return "sidebar.dashboard"
        case .smartClean: return "sidebar.smartClean"
        case .cacheCleaner: return "sidebar.cacheCleaner"
        case .archScanner: return "sidebar.archScanner"
        case .duplicateFinder: return "sidebar.duplicateFinder"
        case .largeFiles: return "sidebar.largeFiles"
        case .uninstaller: return "sidebar.uninstaller"
        case .loginItems: return "sidebar.loginItems"
        case .updateManager: return "sidebar.updateManager"
        case .settings: return "sidebar.settings"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard: return "gauge.with.dots.needle.50percent"
        case .smartClean: return "wand.and.sparkles"
        case .cacheCleaner: return "trash.circle"
        case .archScanner: return "cpu"
        case .duplicateFinder: return "doc.on.doc"
        case .largeFiles: return "doc.badge.plus"
        case .uninstaller: return "minus.circle"
        case .loginItems: return "person.badge.clock"
        case .updateManager: return "arrow.triangle.2.circlepath.circle"
        case .settings: return "gearshape"
        }
    }
}
