import Foundation

/// Elenca le voci di primo livello di una cartella con la relativa dimensione totale,
/// per navigare il disco un livello alla volta (come DaisyDisk/OmniDiskSweeper) invece
/// di affidarsi solo alle categorie fisse degli altri scanner.
enum DiskExplorerService {
    static func listEntries(in directory: URL) async -> [DiskExplorerEntry] {
        let fm = FileManager.default
        guard let items = try? fm.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var results: [DiskExplorerEntry] = []
        await withTaskGroup(of: DiskExplorerEntry?.self) { group in
            for item in items {
                group.addTask {
                    var isDir: ObjCBool = false
                    guard fm.fileExists(atPath: item.path, isDirectory: &isDir) else { return nil }
                    let size: Int64
                    if isDir.boolValue {
                        size = (try? FileSizeScanner.size(ofDirectory: item, skipPackageDescendants: false)) ?? 0
                    } else {
                        size = (try? FileSizeScanner.size(ofFile: item)) ?? 0
                    }
                    return DiskExplorerEntry(path: item, sizeBytes: size, isDirectory: isDir.boolValue)
                }
            }
            for await entry in group {
                if let entry { results.append(entry) }
            }
        }

        return results.sorted { $0.sizeBytes > $1.sizeBytes }
    }
}
