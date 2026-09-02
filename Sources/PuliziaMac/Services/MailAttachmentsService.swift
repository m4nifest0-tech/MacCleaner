import Foundation

/// Scansiona la cache degli allegati Mail: copie scaricate/aperte tramite Mail.app, non
/// gli allegati "veri" conservati nel database dei messaggi (quelli restano intoccati,
/// toccarli rischierebbe di corrompere la posta).
enum MailAttachmentsService {
    static var directory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Containers/com.apple.mail/Data/Library/Mail Downloads")
    }

    struct ScanResult {
        var items: [CleanableItem] = []
        /// Vero se la cartella esiste ma non è leggibile (manca Accesso completo al disco),
        /// per distinguerlo dal caso "nessun allegato in cache" (nessun problema).
        var permissionDenied = false
    }

    static func scan(excludedFolders: [URL] = []) async -> ScanResult {
        let fm = FileManager.default
        let directory = directory
        guard fm.fileExists(atPath: directory.path) else { return ScanResult() }

        let rawEntries: [URL]
        do {
            rawEntries = try fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])
        } catch {
            return ScanResult(items: [], permissionDenied: true)
        }

        let entries = excludedFolders.isEmpty
            ? rawEntries
            : rawEntries.filter { !ExclusionMatcher.isExcluded($0, excludedFolders: excludedFolders) }

        var items: [CleanableItem] = []
        await withTaskGroup(of: CleanableItem?.self) { group in
            for entry in entries {
                group.addTask {
                    var isDir: ObjCBool = false
                    guard fm.fileExists(atPath: entry.path, isDirectory: &isDir) else { return nil }
                    let size: Int64
                    if isDir.boolValue {
                        size = (try? FileSizeScanner.size(ofDirectory: entry)) ?? 0
                    } else {
                        size = (try? FileSizeScanner.size(ofFile: entry)) ?? 0
                    }
                    guard size > 0 else { return nil }
                    return CleanableItem(path: entry, category: .mailAttachments, sizeBytes: size, isDirectory: isDir.boolValue)
                }
            }
            for await item in group {
                if let item { items.append(item) }
            }
        }

        items.sort { $0.sizeBytes > $1.sizeBytes }
        return ScanResult(items: items, permissionDenied: false)
    }
}
