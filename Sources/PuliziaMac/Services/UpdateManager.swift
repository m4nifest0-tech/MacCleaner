import Foundation

/// Controlla e applica aggiornamenti tramite Homebrew e Mac App Store (via `mas`).
/// Non esiste un meccanismo generico per controllare aggiornamenti di app scaricate da
/// siti esterni: per quelle mostriamo solo l'elenco/versione installata altrove nell'app.
enum UpdateManager {
    private static let knownBrewPaths = ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"]
    private static let knownMasPaths = ["/opt/homebrew/bin/mas", "/usr/local/bin/mas"]

    static func locateBrew() -> ToolAvailability {
        locate(candidates: knownBrewPaths)
    }

    static func locateMas() -> ToolAvailability {
        locate(candidates: knownMasPaths)
    }

    private static func locate(candidates: [String]) -> ToolAvailability {
        let fm = FileManager.default
        for path in candidates where fm.isExecutableFile(atPath: path) {
            return .available(path: path)
        }
        return .notInstalled
    }

    // MARK: - Homebrew

    private struct BrewOutdatedV2: Decodable {
        struct Entry: Decodable {
            let name: String
            let installed_versions: [String]
            let current_version: String
        }
        let formulae: [Entry]
        let casks: [Entry]
    }

    static func homebrewOutdated(brewPath: String) async -> [UpdateItem] {
        guard let output = await run(brewPath, ["outdated", "--json=v2"]) else { return [] }
        guard let data = output.data(using: .utf8),
              let parsed = try? JSONDecoder().decode(BrewOutdatedV2.self, from: data) else { return [] }

        let allEntries = parsed.formulae + parsed.casks
        return allEntries.map { entry in
            UpdateItem(
                id: "brew:\(entry.name)",
                source: .homebrew,
                name: entry.name,
                installedVersion: entry.installed_versions.last,
                availableVersion: entry.current_version
            )
        }
    }

    static func upgradeHomebrewPackage(brewPath: String, name: String) async -> Bool {
        await run(brewPath, ["upgrade", name]) != nil
    }

    static func installHomebrewPackage(brewPath: String, name: String) async -> Bool {
        await run(brewPath, ["install", name]) != nil
    }

    // MARK: - Mac App Store (mas-cli)

    /// Righe tipiche: "409183694 Keynote (12.2 -> 13.0)"
    static func parseMasOutdated(_ output: String) -> [UpdateItem] {
        output.split(separator: "\n").compactMap { line -> UpdateItem? in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard let firstSpace = trimmed.firstIndex(of: " ") else { return nil }
            let id = String(trimmed[trimmed.startIndex..<firstSpace])
            guard let openParen = trimmed.lastIndex(of: "("), let closeParen = trimmed.lastIndex(of: ")"), openParen < closeParen else {
                return nil
            }
            let name = trimmed[trimmed.index(after: firstSpace)..<openParen].trimmingCharacters(in: .whitespaces)
            let versions = trimmed[trimmed.index(after: openParen)..<closeParen]
            let parts = versions.components(separatedBy: "->").map { $0.trimmingCharacters(in: .whitespaces) }

            return UpdateItem(
                id: "mas:\(id)",
                source: .masAppStore,
                name: name,
                installedVersion: parts.first,
                availableVersion: parts.count > 1 ? parts[1] : nil
            )
        }
    }

    static func masOutdated(masPath: String) async -> [UpdateItem] {
        guard let output = await run(masPath, ["outdated"]) else { return [] }
        return parseMasOutdated(output)
    }

    static func upgradeMasApp(masPath: String, id: String) async -> Bool {
        await run(masPath, ["upgrade", id]) != nil
    }

    // MARK: - Process helper

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
