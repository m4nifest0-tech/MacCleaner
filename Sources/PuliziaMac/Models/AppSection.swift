import Foundation

enum AppSection: String, CaseIterable, Identifiable, Hashable {
    case dashboard
    case smartClean
    case cacheCleaner
    case archScanner
    case duplicateFinder
    case largeFiles
    case diskExplorer
    case mailAttachments
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
        case .diskExplorer: return "sidebar.diskExplorer"
        case .mailAttachments: return "sidebar.mailAttachments"
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
        case .diskExplorer: return "externaldrive"
        case .mailAttachments: return "paperclip"
        case .uninstaller: return "minus.circle"
        case .loginItems: return "person.badge.clock"
        case .updateManager: return "arrow.triangle.2.circlepath.circle"
        case .settings: return "gearshape"
        }
    }

    /// Tasto numerico assegnato per Cmd+N (le prime 9 voci della sidebar, in ordine);
    /// nil per quelle senza scorciatoia dedicata.
    var keyboardShortcutKey: Character? {
        let numbered: [AppSection] = [.dashboard, .smartClean, .cacheCleaner, .archScanner, .duplicateFinder, .largeFiles, .diskExplorer, .mailAttachments, .uninstaller]
        guard let index = numbered.firstIndex(of: self) else { return nil }
        return Character("\(index + 1)")
    }

    /// Sinonimi/termini extra per la ricerca nella sidebar, oltre al titolo tradotto
    /// (es. "duplicati" deve trovare anche digitando "doppi" o "copie").
    var searchKeywords: [String] {
        switch self {
        case .dashboard: return ["panoramica", "overview", "home", "spazio", "disco", "space"]
        case .smartClean: return ["pulizia", "automatica", "smart", "clean", "dns", "one-click"]
        case .cacheCleaner: return ["cache", "temporanei", "temp", "spazzatura", "junk", "log"]
        case .archScanner: return ["intel", "arm", "rosetta", "universale", "cpu", "apple silicon"]
        case .duplicateFinder: return ["duplicati", "doppi", "duplicate", "copie", "copies"]
        case .largeFiles: return ["grandi", "pesanti", "large", "big", "file"]
        case .diskExplorer: return ["esplora", "disco", "explorer", "treemap", "mappa", "grafica"]
        case .mailAttachments: return ["mail", "posta", "allegati", "attachments", "email"]
        case .uninstaller: return ["disinstalla", "rimuovi", "uninstall", "remove", "elimina"]
        case .loginItems: return ["avvio", "login", "startup", "agenti", "launchagents"]
        case .updateManager: return ["aggiornamenti", "update", "homebrew", "brew", "mas", "app store"]
        case .settings: return ["impostazioni", "preferenze", "lingua", "language", "tema", "theme", "colore", "accento", "eccezioni", "dock"]
        }
    }

    func matches(query: String) -> Bool {
        let needle = query.lowercased()
        return searchKeywords.contains { $0.lowercased().contains(needle) }
    }
}
