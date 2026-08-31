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
    ///
    /// Molte app del Mac App Store sono di proprietà di root (installate dal processo
    /// dell'App Store), quindi un semplice spostamento nel Cestino da un processo utente
    /// normale può fallire per permessi indipendentemente dal permesso "Gestione app".
    /// In quel caso ritentiamo con privilegi di amministratore solo i percorsi falliti.
    static func uninstall(_ candidate: UninstallCandidate, removingLeftovers leftoverPaths: [URL]) async -> [TrashService.Failure] {
        await Task.detached(priority: .userInitiated) {
            let allPaths = [candidate.app.bundleURL] + leftoverPaths
            let failures = TrashService.moveToTrash(allPaths)
            guard !failures.isEmpty else { return [] }

            let permissionFailures = failures.filter { UniversalAppThinner.isPermissionError($0.underlyingError) }
            guard !permissionFailures.isEmpty else { return failures }

            let trashDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".Trash")
            var scriptLines = ["mkdir -p \(ElevatedShell.shellQuoted(trashDir.path))"]
            for failure in permissionFailures {
                let destination = trashDir.appendingPathComponent(failure.path.lastPathComponent)
                let quotedSource = ElevatedShell.shellQuoted(failure.path.path)
                let quotedDestination = ElevatedShell.shellQuoted(destination.path)
                // Rimuove un eventuale residuo di un tentativo precedente prima di
                // spostare: senza questo, `mv` su una destinazione già esistente (es.
                // una directory con lo stesso nome) può fallire o finire nel posto
                // sbagliato invece di sovrascrivere.
                scriptLines.append("rm -rf \(quotedDestination)")
                scriptLines.append("mv -f \(quotedSource) \(quotedDestination)")
            }

            let result = ElevatedShell.run(scriptLines)
            if result.success {
                // Tutti i percorsi bloccati per permessi sono stati spostati: restano
                // solo gli eventuali fallimenti non legati a un problema di permessi.
                return failures.filter { !UniversalAppThinner.isPermissionError($0.underlyingError) }
            }
            // L'elevazione è stata annullata o non è riuscita: i fallimenti originali restano.
            return failures
        }.value
    }
}
