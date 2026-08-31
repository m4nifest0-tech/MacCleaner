import Foundation

/// Scansiona le app installate per trovare quelle prive di una slice nativa arm64,
/// cioè quelle che su un Mac Apple Silicon girano solo tramite la traduzione Rosetta 2.
enum ArchScanner {
    static let searchDirectories: [URL] = [
        URL(fileURLWithPath: "/Applications"),
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications")
    ]

    static func scan() async -> [AppBundleInfo] {
        let appURLs = findAppBundles()
        var results: [AppBundleInfo] = []

        await withTaskGroup(of: AppBundleInfo?.self) { group in
            for appURL in appURLs {
                group.addTask {
                    inspect(appBundle: appURL)
                }
            }
            for await info in group {
                if let info { results.append(info) }
            }
        }

        return results.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// Trova tutte le cartelle .app di primo livello (e nelle sottocartelle immediate,
    /// es. /Applications/Utilities) nelle directory di ricerca note.
    private static func findAppBundles() -> [URL] {
        let fm = FileManager.default
        var found: [URL] = []

        func scanLevel(_ directory: URL, depth: Int) {
            guard depth <= 2, let entries = try? fm.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) else { return }

            for entry in entries {
                if entry.pathExtension == "app" {
                    found.append(entry)
                } else if (try? entry.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true {
                    scanLevel(entry, depth: depth + 1)
                }
            }
        }

        for directory in searchDirectories {
            scanLevel(directory, depth: 0)
        }
        return found
    }

    private static func inspect(appBundle: URL) -> AppBundleInfo? {
        guard let bundle = Bundle(url: appBundle) else { return nil }
        guard let executableURL = bundle.executableURL else { return nil }

        let architectures = architectures(ofExecutable: executableURL)
        guard !architectures.isEmpty else { return nil }

        let size = (try? FileSizeScanner.size(ofDirectory: appBundle, skipPackageDescendants: false)) ?? 0

        return AppBundleInfo(
            bundleURL: appBundle,
            bundleIdentifier: bundle.bundleIdentifier,
            version: bundle.infoDictionary?["CFBundleShortVersionString"] as? String,
            architectures: architectures,
            sizeBytes: size
        )
    }

    static func architectures(ofExecutable url: URL) -> [String] {
        if let output = run("/usr/bin/lipo", ["-info", url.path]), let archs = parseLipoOutput(output) {
            return archs
        }
        if let output = run("/usr/bin/file", [url.path]), let archs = parseFileOutput(output) {
            return archs
        }
        return []
    }

    /// Estrae le architetture da `lipo -info`. Gestisce sia i binari universali
    /// ("Architectures in the fat file: ... are: x86_64 arm64") sia quelli a
    /// architettura singola ("Non-fat file: ... is architecture: x86_64").
    static func parseLipoOutput(_ output: String) -> [String]? {
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        if let range = trimmed.range(of: "are:") {
            let list = trimmed[range.upperBound...]
            let archs = list.split(separator: " ").map(String.init).filter { !$0.isEmpty }
            return archs.isEmpty ? nil : archs
        }
        if let range = trimmed.range(of: "is architecture:") {
            let arch = trimmed[range.upperBound...].trimmingCharacters(in: .whitespaces)
            return arch.isEmpty ? nil : [arch]
        }
        return nil
    }

    /// Fallback basato sull'output di `file` quando `lipo` non è disponibile o fallisce.
    static func parseFileOutput(_ output: String) -> [String]? {
        var archs: Set<String> = []
        for candidate in ["arm64e", "arm64", "x86_64"] {
            if output.contains(candidate) {
                archs.insert(candidate == "arm64e" ? "arm64" : candidate)
            }
        }
        return archs.isEmpty ? nil : Array(archs)
    }

    private static func run(_ launchPath: String, _ arguments: [String]) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = arguments

        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe

        do {
            try process.run()
        } catch {
            return nil
        }
        process.waitUntilExit()

        let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
        let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
        let combined = String(data: outData, encoding: .utf8).map { $0 + (String(data: errData, encoding: .utf8) ?? "") }
        return combined
    }
}
