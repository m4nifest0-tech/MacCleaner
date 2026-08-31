import Foundation

/// Esegue uno script shell con privilegi di amministratore tramite un'unica richiesta
/// di password/Touch ID di sistema (AppleScript `do shell script ... with administrator
/// privileges`). Usato per le poche operazioni che richiedono root: disattivare
/// LaunchAgents di sistema, svuotare la cache DNS.
///
/// Nota: `UniversalAppThinner` ha una propria copia di questo meccanismo (script più
/// lungo e gestione d'errore specifica per il gate TCC "Gestione app") e non lo
/// riusa, per non rischiare regressioni su un percorso già verificato end-to-end.
enum ElevatedShell {
    struct Result {
        let success: Bool
        let errorMessage: String?
    }

    static func run(_ scriptLines: [String]) -> Result {
        let (exitCode, stderr) = runRaw(scriptLines)
        if exitCode == 0 { return Result(success: true, errorMessage: nil) }
        if stderr.contains("User canceled") || stderr.contains("-128") {
            return Result(success: false, errorMessage: Localization.string("svc.elevation_cancelled", language: AppLanguage.current))
        }
        return Result(success: false, errorMessage: Localization.string("svc.elevation_failed", language: AppLanguage.current))
    }

    static func runRaw(_ scriptLines: [String]) -> (exitCode: Int32, stderr: String) {
        let scriptFile = FileManager.default.temporaryDirectory.appendingPathComponent("puliziamac_elevated_\(UUID().uuidString).sh")
        do {
            try (["set -e"] + scriptLines).joined(separator: "\n").write(to: scriptFile, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: scriptFile.path)
        } catch {
            return (-1, error.localizedDescription)
        }
        defer { try? FileManager.default.removeItem(at: scriptFile) }

        let shellCommand = "/bin/bash " + shellQuoted(scriptFile.path)
        let appleScriptSource = "do shell script \(appleScriptQuoted(shellCommand)) with administrator privileges"
        return runProcessCapturingError("/usr/bin/osascript", ["-e", appleScriptSource])
    }

    static func shellQuoted(_ path: String) -> String {
        "'" + path.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    static func appleScriptQuoted(_ s: String) -> String {
        "\"" + s.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"") + "\""
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
