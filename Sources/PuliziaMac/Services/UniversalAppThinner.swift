import Foundation

/// Rimuove la slice Intel (x86_64) dai binari universali di un'app, tenendo solo
/// arm64, e ri-firma il bundle. Operazione irreversibile (nessun backup automatico):
/// se l'app smette di funzionare dopo l'operazione va reinstallata/riscaricata.
///
/// Le app scaricate dal Mac App Store sono sempre escluse: verificano la propria firma
/// Apple originale all'avvio e si rompono quasi certamente se ri-firmate.
enum UniversalAppThinner {
    struct NotEligible: Error {
        let reason: String
    }

    private static func t(_ key: String) -> String {
        Localization.string(key, language: AppLanguage.current)
    }

    /// Magic number dei binari Mach-O "fat" (universali): 0xCAFEBABE (32 bit) o
    /// 0xCAFEBABF (64 bit), sempre big-endian nel file.
    private static let fatMagics: Set<UInt32> = [0xcafebabe, 0xcafebabf]

    static func hasMachOFatMagic(_ url: URL) -> Bool {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return false }
        defer { try? handle.close() }
        guard let data = try? handle.read(upToCount: 4), data.count == 4 else { return false }
        let magic = data.withUnsafeBytes { $0.load(as: UInt32.self) }.bigEndian
        return fatMagics.contains(magic)
    }

    /// Trova tutti i binari universali (arm64 + x86_64) all'interno del bundle.
    static func fatBinaries(in bundleURL: URL) -> [URL] {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(
            at: bundleURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var found: [URL] = []
        while let url = enumerator.nextObject() as? URL {
            guard let isRegular = try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile,
                  isRegular, hasMachOFatMagic(url) else { continue }
            let archs = ArchScanner.architectures(ofExecutable: url)
            if archs.contains("arm64") && archs.contains("x86_64") {
                found.append(url)
            }
        }
        return found
    }

    /// Stima lo spazio recuperabile tenendo solo arm64, senza modificare nulla:
    /// estrae ogni binario in un file temporaneo e confronta le dimensioni.
    static func estimateIntelSavings(for bundleURL: URL) async -> Int64 {
        await Task.detached(priority: .userInitiated) {
            var totalSavings: Int64 = 0
            for binary in fatBinaries(in: bundleURL) {
                let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
                defer { try? FileManager.default.removeItem(at: tmp) }
                guard runLipo(["-thin", "arm64", "-output", tmp.path, binary.path]) else { continue }
                let before = (try? FileSizeScanner.size(ofFile: binary)) ?? 0
                let after = (try? FileSizeScanner.size(ofFile: tmp)) ?? 0
                totalSavings += max(before - after, 0)
            }
            return totalSavings
        }.value
    }

    /// Vero se scrivere direttamente nel bundle richiede i permessi di amministratore:
    /// capita con le app installate da un installer .pkg che gira come root (es. molte
    /// app Adobe, o pacchetti distribuiti così anziché come semplice drag&drop).
    static func needsElevation(for app: AppBundleInfo) -> Bool {
        let fm = FileManager.default
        if !fm.isWritableFile(atPath: app.bundleURL.path) { return true }
        for binary in fatBinaries(in: app.bundleURL) {
            if !fm.isWritableFile(atPath: binary.deletingLastPathComponent().path) {
                return true
            }
        }
        return false
    }

    private struct Outcome {
        let success: Bool
        let errorMessage: String?
        var requiresAppManagementPermission = false
    }

    static func removeIntelSlice(from app: AppBundleInfo) async -> ThinResult {
        guard !app.isMacAppStoreApp else {
            return ThinResult(appName: app.name, sizeBefore: app.sizeBytes, sizeAfter: app.sizeBytes, success: false, errorMessage: t("svc.mas_excluded"))
        }

        return await Task.detached(priority: .userInitiated) {
            let sizeBefore = (try? FileSizeScanner.size(ofDirectory: app.bundleURL, skipPackageDescendants: false)) ?? app.sizeBytes
            let binaries = fatBinaries(in: app.bundleURL)

            let outcome: Outcome
            if needsElevation(for: app) {
                outcome = removeIntelSliceElevated(binaries: binaries, bundleURL: app.bundleURL)
            } else {
                let attempt = removeIntelSliceUnprivileged(binaries: binaries, bundleURL: app.bundleURL)
                switch attempt {
                case .success:
                    outcome = Outcome(success: true, errorMessage: nil)
                case .permissionDeniedBeforeAnyChange:
                    // I permessi POSIX sembravano ok, ma macOS ha comunque bloccato la scrittura
                    // (tipicamente il permesso "Gestione app" in Privacy e Sicurezza non è ancora
                    // concesso a PuliziaMac). Nessun file è stato toccato: si può ritentare con
                    // privilegi di amministratore in sicurezza.
                    outcome = removeIntelSliceElevated(binaries: binaries, bundleURL: app.bundleURL)
                case .failure(let message):
                    outcome = Outcome(success: false, errorMessage: message)
                }
            }

            guard outcome.success else {
                return ThinResult(appName: app.name, sizeBefore: sizeBefore, sizeAfter: sizeBefore, success: false, errorMessage: outcome.errorMessage, requiresAppManagementPermission: outcome.requiresAppManagementPermission)
            }

            let sizeAfter = (try? FileSizeScanner.size(ofDirectory: app.bundleURL, skipPackageDescendants: false)) ?? sizeBefore
            return ThinResult(appName: app.name, sizeBefore: sizeBefore, sizeAfter: sizeAfter, success: true, errorMessage: nil)
        }.value
    }

    private enum UnprivilegedAttempt {
        case success
        /// Fallito sul primo binario, prima di aver modificato qualunque cosa: si può
        /// ritentare con privilegi di amministratore senza rischio di stato incoerente.
        case permissionDeniedBeforeAnyChange
        case failure(String)
    }

    private static func removeIntelSliceUnprivileged(binaries: [URL], bundleURL: URL) -> UnprivilegedAttempt {
        for (index, binary) in binaries.enumerated() {
            let tmp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            guard runLipo(["-thin", "arm64", "-output", tmp.path, binary.path]) else {
                try? FileManager.default.removeItem(at: tmp)
                let message = AppLanguage.current == .italian
                    ? "Impossibile estrarre arm64 da \(binary.lastPathComponent)."
                    : "Couldn't extract arm64 from \(binary.lastPathComponent)."
                return .failure(message)
            }
            do {
                let originalPermissions = try FileManager.default.attributesOfItem(atPath: binary.path)[.posixPermissions]
                _ = try FileManager.default.replaceItemAt(binary, withItemAt: tmp)
                if let originalPermissions {
                    try? FileManager.default.setAttributes([.posixPermissions: originalPermissions], ofItemAtPath: binary.path)
                }
            } catch {
                try? FileManager.default.removeItem(at: tmp)
                if index == 0, isPermissionError(error) {
                    return .permissionDeniedBeforeAnyChange
                }
                let message = AppLanguage.current == .italian
                    ? "Impossibile sostituire \(binary.lastPathComponent): \(error.localizedDescription)"
                    : "Couldn't replace \(binary.lastPathComponent): \(error.localizedDescription)"
                return .failure(message)
            }
        }

        guard resign(bundleURL) else {
            return .failure(t("svc.thin_failed_resign"))
        }
        return .success
    }

    static func isPermissionError(_ error: Error) -> Bool {
        let nsError = error as NSError
        if nsError.code == NSFileWriteNoPermissionError || nsError.code == NSFileWriteVolumeReadOnlyError {
            return true
        }
        return nsError.localizedDescription.lowercased().contains("permission")
    }

    /// Le stesse operazioni di `removeIntelSliceUnprivileged`, ma eseguite come un unico
    /// script shell con privilegi di amministratore (una sola richiesta di password/Touch
    /// ID all'utente), per le app installate con permessi da root.
    ///
    /// Nota: se il blocco è dovuto al permesso "Gestione app" (macOS lo applica anche ai
    /// processi con privilegi di amministratore, root incluso, perché non è un controllo
    /// POSIX ma una policy TCC legata al processo chiamante), neanche l'elevazione basta:
    /// va concesso esplicitamente in Impostazioni di Sistema.
    private static func removeIntelSliceElevated(binaries: [URL], bundleURL: URL) -> Outcome {
        guard !binaries.isEmpty else {
            return resign(bundleURL) ? Outcome(success: true, errorMessage: nil) : Outcome(success: false, errorMessage: t("svc.resign_failed"))
        }

        var scriptLines = ["set -e"]
        for (index, binary) in binaries.enumerated() {
            let path = shellQuoted(binary.path)
            let tmp = shellQuoted(binary.path + ".puliziamac_thin")
            scriptLines.append("PERM_\(index)=$(stat -f%Mp%Lp \(path))")
            scriptLines.append("lipo -thin arm64 -output \(tmp) \(path)")
            scriptLines.append("mv -f \(tmp) \(path)")
            scriptLines.append("chmod \"$PERM_\(index)\" \(path)")
        }
        scriptLines.append("/usr/bin/codesign --force --deep --preserve-metadata=entitlements,identifier --sign - \(shellQuoted(bundleURL.path))")

        let scriptFile = FileManager.default.temporaryDirectory.appendingPathComponent("puliziamac_thin_\(UUID().uuidString).sh")
        do {
            try scriptLines.joined(separator: "\n").write(to: scriptFile, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: scriptFile.path)
        } catch {
            return Outcome(success: false, errorMessage: t("svc.elevation_prepare_failed"))
        }
        defer { try? FileManager.default.removeItem(at: scriptFile) }

        let shellCommand = "/bin/bash " + shellQuoted(scriptFile.path)
        let appleScriptSource = "do shell script \(appleScriptQuoted(shellCommand)) with administrator privileges"

        let (exitCode, stderr) = runProcessCapturingError("/usr/bin/osascript", ["-e", appleScriptSource])
        if exitCode == 0 {
            return Outcome(success: true, errorMessage: nil)
        }
        if stderr.contains("User canceled") || stderr.contains("-128") {
            return Outcome(success: false, errorMessage: t("svc.elevation_cancelled"))
        }
        if isAppManagementError(stderr) {
            return Outcome(
                success: false,
                errorMessage: t("svc.app_management_required"),
                requiresAppManagementPermission: true
            )
        }
        let detail = stderr.trimmingCharacters(in: .whitespacesAndNewlines)
        let detailLabel = AppLanguage.current == .italian ? "Dettaglio" : "Detail"
        let suffix = detail.isEmpty ? "" : " \(detailLabel): \(detail)"
        return Outcome(success: false, errorMessage: "\(t("svc.elevation_failed"))\(suffix)")
    }

    /// "Operation not permitted" da un processo con privilegi di amministratore, su un file
    /// per cui i permessi POSIX risultavano ok, è il sintomo tipico del gate TCC "Gestione
    /// app" (introdotto per impedire ad app come questa di modificare altre app senza
    /// consenso esplicito) — non di un vero problema di proprietà/permessi del file.
    static func isAppManagementError(_ stderr: String) -> Bool {
        stderr.localizedCaseInsensitiveContains("Operation not permitted")
    }

    static func shellQuoted(_ path: String) -> String {
        "'" + path.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    static func appleScriptQuoted(_ s: String) -> String {
        "\"" + s.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"") + "\""
    }

    /// Non preserviamo il flag "hardened runtime": una volta ri-firmata ad-hoc (senza il
    /// Team ID originale), tenerlo attivo fa fallire la validazione delle librerie interne
    /// a dyld ("different Team IDs") e l'app non si avvia più.
    private static func resign(_ bundleURL: URL) -> Bool {
        runProcess("/usr/bin/codesign", ["--force", "--deep", "--preserve-metadata=entitlements,identifier", "--sign", "-", bundleURL.path])
    }

    private static func runLipo(_ arguments: [String]) -> Bool {
        runProcess("/usr/bin/lipo", arguments)
    }

    private static func runProcess(_ launchPath: String, _ arguments: [String]) -> Bool {
        runProcessCapturingError(launchPath, arguments).0 == 0
    }

    private static func runProcessCapturingError(_ launchPath: String, _ arguments: [String]) -> (Int32, String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = arguments
        process.standardOutput = Pipe()
        let errPipe = Pipe()
        process.standardError = errPipe
        do {
            try process.run()
        } catch {
            return (-1, error.localizedDescription)
        }
        let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return (process.terminationStatus, String(data: errData, encoding: .utf8) ?? "")
    }
}
