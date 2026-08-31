import Foundation

/// Scansiona le posizioni note di cache/file temporanei e produce una lista di
/// `CleanableItem` con le dimensioni calcolate. Ogni voce può essere selezionata
/// dall'utente e spostata nel Cestino tramite `TrashService`.
enum CacheScanner {
    struct ScanResult {
        var items: [CleanableItem] = []
        var permissionIssues: [URL] = []
    }

    static func scan(excludedFolders: [URL] = []) async -> ScanResult {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let fm = FileManager.default

        var jobs: [(URL, CleanableCategory)] = []

        // Cache per-app: ogni sottocartella di ~/Library/Caches è un'app/servizio diverso.
        let userCaches = home.appendingPathComponent("Library/Caches")
        for entry in FileSizeScanner.topLevelEntries(of: userCaches) {
            jobs.append((entry, .appCaches))
        }

        // Log utente (include anche DiagnosticReports come sottocartella).
        let userLogs = home.appendingPathComponent("Library/Logs")
        for entry in FileSizeScanner.topLevelEntries(of: userLogs) {
            jobs.append((entry, .logs))
        }

        // Strumenti sviluppatore non già coperti da ~/Library/Caches.
        let developerPaths = [
            home.appendingPathComponent("Library/Developer/Xcode/DerivedData"),
            home.appendingPathComponent("Library/Developer/Xcode/Archives"),
            home.appendingPathComponent(".npm"),
            home.appendingPathComponent(".cache")
        ]
        for path in developerPaths where fm.fileExists(atPath: path.path) {
            jobs.append((path, .developer))
        }

        // Installer scaricati in ~/Downloads (solo primo livello, estensioni note).
        let downloads = home.appendingPathComponent("Downloads")
        let installerExtensions: Set<String> = ["dmg", "pkg", "zip"]
        for entry in FileSizeScanner.topLevelEntries(of: downloads) {
            if installerExtensions.contains(entry.pathExtension.lowercased()) {
                jobs.append((entry, .downloadsInstallers))
            }
        }

        if !excludedFolders.isEmpty {
            jobs.removeAll { ExclusionMatcher.isExcluded($0.0, excludedFolders: excludedFolders) }
        }

        var result = ScanResult()

        // Cestino: dimensione complessiva come voce unica.
        let trash = home.appendingPathComponent(".Trash")
        if fm.fileExists(atPath: trash.path) {
            if let size = try? FileSizeScanner.size(ofDirectory: trash), size > 0 {
                result.items.append(CleanableItem(path: trash, category: .trash, sizeBytes: size, isDirectory: true))
            }
        }

        await withTaskGroup(of: Result<CleanableItem, FileSizeScanner.PermissionDenied>.self) { group in
            for (path, category) in jobs {
                group.addTask {
                    var isDir: ObjCBool = false
                    guard fm.fileExists(atPath: path.path, isDirectory: &isDir) else {
                        return .failure(FileSizeScanner.PermissionDenied(path: path))
                    }
                    do {
                        let size: Int64
                        if isDir.boolValue {
                            size = try FileSizeScanner.size(ofDirectory: path)
                        } else {
                            size = try FileSizeScanner.size(ofFile: path)
                        }
                        return .success(CleanableItem(path: path, category: category, sizeBytes: size, isDirectory: isDir.boolValue))
                    } catch {
                        return .failure(FileSizeScanner.PermissionDenied(path: path))
                    }
                }
            }

            for await outcome in group {
                switch outcome {
                case .success(let item) where item.sizeBytes > 0:
                    result.items.append(item)
                case .success:
                    break
                case .failure(let denied):
                    result.permissionIssues.append(denied.path)
                }
            }
        }

        result.items.sort { $0.sizeBytes > $1.sizeBytes }
        return result
    }
}
