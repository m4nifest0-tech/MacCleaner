import Foundation

/// Cerca i file residui di un'app (preferenze, cache, application support, log, stato
/// salvato, container) in base al bundle identifier e al nome dell'app. Il confronto è
/// volutamente esatto (non fuzzy) per non rischiare di segnalare file di app diverse.
enum UninstallerService {
    /// Percorsi candidati (non ancora verificati) dove possono trovarsi i residui di
    /// un'app, dati bundle identifier, nome app e home directory dell'utente.
    /// Funzione pura, testabile senza toccare il filesystem reale.
    static func candidatePaths(bundleIdentifier: String?, appName: String, home: URL) -> [URL] {
        var paths: [URL] = []
        let library = home.appendingPathComponent("Library")

        paths.append(library.appendingPathComponent("Application Support/\(appName)"))
        paths.append(library.appendingPathComponent("Caches/\(appName)"))
        paths.append(library.appendingPathComponent("Logs/\(appName)"))

        if let bundleIdentifier {
            paths.append(library.appendingPathComponent("Application Support/\(bundleIdentifier)"))
            paths.append(library.appendingPathComponent("Caches/\(bundleIdentifier)"))
            paths.append(library.appendingPathComponent("Preferences/\(bundleIdentifier).plist"))
            paths.append(library.appendingPathComponent("Saved Application State/\(bundleIdentifier).savedState"))
            paths.append(library.appendingPathComponent("Containers/\(bundleIdentifier)"))
            paths.append(library.appendingPathComponent("HTTPStorages/\(bundleIdentifier)"))
            paths.append(library.appendingPathComponent("WebKit/\(bundleIdentifier)"))
            paths.append(library.appendingPathComponent("LaunchAgents/\(bundleIdentifier).plist"))
        }

        return paths
    }

    static func findLeftovers(for app: AppBundleInfo) async -> [LeftoverFile] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let candidates = candidatePaths(bundleIdentifier: app.bundleIdentifier, appName: app.name, home: home)
        let fm = FileManager.default

        var leftovers: [LeftoverFile] = []
        await withTaskGroup(of: LeftoverFile?.self) { group in
            for path in candidates {
                group.addTask {
                    var isDir: ObjCBool = false
                    guard fm.fileExists(atPath: path.path, isDirectory: &isDir) else { return nil }
                    let size: Int64
                    if isDir.boolValue {
                        size = (try? FileSizeScanner.size(ofDirectory: path)) ?? 0
                    } else {
                        size = (try? FileSizeScanner.size(ofFile: path)) ?? 0
                    }
                    return LeftoverFile(path: path, sizeBytes: size)
                }
            }
            for await leftover in group {
                if let leftover { leftovers.append(leftover) }
            }
        }
        return leftovers.sorted { $0.sizeBytes > $1.sizeBytes }
    }

    /// Disinstalla l'app: sposta nel Cestino il bundle .app e tutti i residui indicati.
    static func uninstall(_ candidate: UninstallCandidate, removingLeftovers leftoverPaths: [URL]) -> [TrashService.Failure] {
        TrashService.moveToTrash([candidate.app.bundleURL] + leftoverPaths)
    }
}
