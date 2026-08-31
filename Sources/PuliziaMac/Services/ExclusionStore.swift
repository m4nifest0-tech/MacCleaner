import Foundation

/// Logica pura di corrispondenza cartella esclusa, separata da `ExclusionStore` per
/// poterla testare senza bisogno di `UserDefaults`.
enum ExclusionMatcher {
    static func isExcluded(_ url: URL, excludedFolders: [URL]) -> Bool {
        let path = url.standardizedFileURL.path
        return excludedFolders.contains { excluded in
            let excludedPath = excluded.standardizedFileURL.path
            return path == excludedPath || path.hasPrefix(excludedPath + "/")
        }
    }
}

/// Elenco di cartelle che l'utente vuole escludere sempre dalle scansioni (cache, file
/// duplicati, file di grandi dimensioni): una volta aggiunta una cartella qui, PuliziaMac
/// non la propone mai più per la pulizia.
final class ExclusionStore: ObservableObject {
    @Published private(set) var excludedFolders: [URL] {
        didSet { defaults.set(excludedFolders.map(\.path), forKey: Keys.excluded) }
    }

    private let defaults: UserDefaults

    private enum Keys {
        static let excluded = "exclusionExcludedFolders"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        excludedFolders = (defaults.stringArray(forKey: Keys.excluded) ?? []).map { URL(fileURLWithPath: $0) }
    }

    func add(_ url: URL) {
        let standardized = url.standardizedFileURL
        guard !excludedFolders.contains(standardized) else { return }
        excludedFolders.append(standardized)
    }

    func remove(_ url: URL) {
        excludedFolders.removeAll { $0 == url }
    }

    func isExcluded(_ url: URL) -> Bool {
        ExclusionMatcher.isExcluded(url, excludedFolders: excludedFolders)
    }
}
