import Foundation

/// Un file/cartella di cache mostrato nella sezione "Dati di Sistema" (distinto da
/// `CleanableItem` perché non appartiene a nessuna `CleanableCategory` della Cache
/// Cleaner: è una sezione a sé, con le sue azioni dedicate).
struct SystemDataFile: Identifiable, Hashable {
    let id: URL
    let name: String
    let path: URL
    let sizeBytes: Int64
}

/// Analizza le voci che macOS raggruppa sotto "Dati di Sistema" in Informazioni su
/// questo Mac: snapshot locali APFS, cache di Spotlight/QuickLook/CoreSimulator.
/// A differenza della Cache Cleaner, qui ogni voce ha un'azione dedicata invece dello
/// spostamento diretto nel Cestino, perché snapshot e indice Spotlight non sono file
/// normali (si rimuovono con `tmutil`/`mdutil`, non con `FileManager.trashItem`).
enum SystemDataScanner {
    struct ScanResult {
        var snapshots: [APFSSnapshot] = []
        var quickLookCache: SystemDataFile?
        var coreSimulatorCache: SystemDataFile?
        var spotlightIndexSize: Int64?
        var spotlightPermissionDenied = false
    }

    static func scan() async -> ScanResult {
        async let snapshots = listSnapshots()
        async let quickLook = cacheFile(at: quickLookCacheURL, name: "QuickLook")
        async let coreSimulator = cacheFile(at: coreSimulatorCacheURL, name: "CoreSimulator")
        async let spotlight = spotlightSize()

        var result = ScanResult()
        result.snapshots = await snapshots
        result.quickLookCache = await quickLook
        result.coreSimulatorCache = await coreSimulator
        (result.spotlightIndexSize, result.spotlightPermissionDenied) = await spotlight
        return result
    }

    /// Elimina uno snapshot locale: verificato che non richiede privilegi di
    /// amministratore per gli snapshot dell'utente corrente (a differenza di altre
    /// operazioni root-only dell'app, come lo svuotamento della cache DNS).
    static func deleteSnapshot(_ snapshot: APFSSnapshot) async -> Bool {
        await run("/usr/bin/tmutil", ["deletelocalsnapshots", snapshot.id]) != nil
    }

    /// A differenza delle altre cache, l'indice di Spotlight non si "elimina": si
    /// ricostruisce (`mdutil -E`), l'unico modo supportato per svuotarlo e farlo
    /// rigenerare. Richiede privilegi di amministratore sul volume di sistema.
    static func rebuildSpotlightIndex() -> ElevatedShell.Result {
        ElevatedShell.run(["/usr/bin/mdutil -E /"])
    }

    private static var quickLookCacheURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Caches/com.apple.QuickLook.thumbnailcache")
    }

    private static var coreSimulatorCacheURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Developer/CoreSimulator/Caches")
    }

    private static func cacheFile(at url: URL, name: String) async -> SystemDataFile? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let size = (try? FileSizeScanner.size(ofDirectory: url)) ?? 0
        return SystemDataFile(id: url, name: name, path: url, sizeBytes: size)
    }

    /// L'indice di Spotlight del volume dati è protetto anche con Full Disk Access
    /// concesso: se non è leggibile lo segnaliamo invece di mostrare "0 byte".
    private static func spotlightSize() async -> (Int64?, Bool) {
        let url = URL(fileURLWithPath: "/System/Volumes/Data/.Spotlight-V100")
        guard FileManager.default.fileExists(atPath: url.path) else { return (nil, false) }
        do {
            return (try FileSizeScanner.size(ofDirectory: url), false)
        } catch {
            return (nil, true)
        }
    }

    private static let snapshotDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    static func parseSnapshotList(_ output: String) -> [APFSSnapshot] {
        let prefix = "com.apple.TimeMachine."
        let suffix = ".local"
        return output.split(separator: "\n").compactMap { rawLine -> APFSSnapshot? in
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard line.hasPrefix(prefix) else { return nil }
            var dateComponent = String(line.dropFirst(prefix.count))
            if dateComponent.hasSuffix(suffix) {
                dateComponent = String(dateComponent.dropLast(suffix.count))
            }
            let date = snapshotDateFormatter.date(from: dateComponent)
            return APFSSnapshot(id: dateComponent, fullName: line, date: date)
        }
    }

    private static func listSnapshots() async -> [APFSSnapshot] {
        guard let output = await run("/usr/bin/tmutil", ["listlocalsnapshots", "/"]) else { return [] }
        return parseSnapshotList(output)
    }

    private static func run(_ launchPath: String, _ arguments: [String]) async -> String? {
        await withCheckedContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: launchPath)
            process.arguments = arguments

            let outPipe = Pipe()
            process.standardOutput = outPipe
            process.standardError = Pipe()

            process.terminationHandler = { proc in
                let data = outPipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8)
                continuation.resume(returning: proc.terminationStatus == 0 ? (output ?? "") : nil)
            }

            do {
                try process.run()
            } catch {
                continuation.resume(returning: nil)
            }
        }
    }
}
