import Foundation

/// Una cache di un browser (distinta da `CleanableItem`/`CleanableCategory`: non è
/// una categoria della Cache Cleaner generica, ma una sezione dedicata che mostra
/// subito "di chi" è ogni cache invece di un nome di cartella generico).
struct BrowserCacheItem: Identifiable, Hashable {
    let id: URL
    let browserName: String
    let path: URL
    let sizeBytes: Int64
}

/// Scansiona le cartelle cache (non cronologia, non cookie, non password, non
/// preferiti: solo `~/Library/Caches/...`, le cartelle che macOS considera già
/// ricreabili su richiesta) dei browser più comuni su macOS.
enum BrowserCacheScanner {
    struct ScanResult {
        var items: [BrowserCacheItem] = []
        var permissionIssues: Int = 0
    }

    /// Percorso relativo a `~/Library/`. Safari vive in un container sandboxato dal
    /// 10.15 in poi; gli altri sono tutti cache Chromium/Gecko dentro `Caches/`.
    private static let knownCaches: [(name: String, relativeToLibrary: String)] = [
        ("Safari", "Containers/com.apple.Safari/Data/Library/Caches"),
        ("Google Chrome", "Caches/Google/Chrome"),
        ("Brave", "Caches/BraveSoftware"),
        ("Firefox", "Caches/Firefox"),
        ("Microsoft Edge", "Caches/Microsoft Edge")
    ]

    static func scan() async -> ScanResult {
        let library = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library")
        let fm = FileManager.default

        var result = ScanResult()
        await withTaskGroup(of: Result<BrowserCacheItem?, Error>.self) { group in
            for entry in knownCaches {
                group.addTask {
                    let url = library.appendingPathComponent(entry.relativeToLibrary)
                    guard fm.fileExists(atPath: url.path) else { return .success(nil) }
                    do {
                        let size = try FileSizeScanner.size(ofDirectory: url)
                        guard size > 0 else { return .success(nil) }
                        return .success(BrowserCacheItem(id: url, browserName: entry.name, path: url, sizeBytes: size))
                    } catch {
                        return .failure(error)
                    }
                }
            }
            for await outcome in group {
                switch outcome {
                case .success(let item):
                    if let item { result.items.append(item) }
                case .failure:
                    result.permissionIssues += 1
                }
            }
        }

        result.items.sort { $0.sizeBytes > $1.sizeBytes }
        return result
    }
}
