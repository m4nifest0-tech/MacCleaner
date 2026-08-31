import Foundation

/// Elenca e disattiva gli "agenti di avvio" (LaunchAgents) registrati per l'utente o
/// per il sistema: sono la parte pubblica e documentata di "cosa parte da solo al
/// login" — coprono la maggior parte degli helper in background che le app installano
/// (aggiornatori, servizi cloud, ecc.). I "Elementi di Login" classici mostrati in
/// Impostazioni di Sistema → Generali usano invece un formato interno non documentato
/// da Apple, quindi non sono elencabili in modo affidabile da un'app di terze parti.
enum LoginItemsService {
    private static var userLaunchAgentsDir: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/LaunchAgents")
    }
    private static let systemLaunchAgentsDir = URL(fileURLWithPath: "/Library/LaunchAgents")

    static func scan() -> [LoginItem] {
        let fm = FileManager.default
        var items: [LoginItem] = []

        for (directory, scope) in [(userLaunchAgentsDir, LoginItemScope.user), (systemLaunchAgentsDir, .system)] {
            guard let entries = try? fm.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) else { continue }
            for entry in entries where entry.pathExtension == "plist" {
                guard let data = try? Data(contentsOf: entry),
                      let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else { continue }
                let label = (plist["Label"] as? String) ?? entry.deletingPathExtension().lastPathComponent
                let programPath = (plist["Program"] as? String) ?? (plist["ProgramArguments"] as? [String])?.first
                items.append(LoginItem(id: entry, label: label, programPath: programPath, scope: scope))
            }
        }

        return items.sorted { $0.label.localizedCaseInsensitiveCompare($1.label) == .orderedAscending }
    }

    /// Estrae dal Label (in stile reverse-DNS, es. "com.adobe.ARM") un nome più leggibile
    /// da mostrare quando non si riesce a risolvere l'icona/nome dell'app associata.
    static func displayName(for item: LoginItem) -> String {
        let lastComponent = item.label.split(separator: ".").last.map(String.init) ?? item.label
        return lastComponent.isEmpty ? item.label : lastComponent
    }

    /// Se il Program/ProgramArguments punta dentro un bundle .app, ritorna l'URL
    /// dell'app per poterne mostrare l'icona reale.
    static func appBundleURL(for item: LoginItem) -> URL? {
        guard let programPath = item.programPath else { return nil }
        guard let range = programPath.range(of: ".app/") else { return nil }
        let appPath = String(programPath[programPath.startIndex..<range.upperBound]).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let url = URL(fileURLWithPath: "/" + appPath)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    /// Disattiva un agente: lo scarica dalla sessione corrente (se attivo) e sposta il
    /// suo file .plist nel Cestino, così non ripartirà nemmeno al prossimo login.
    /// Le voci di sistema (proprietà di root) richiedono i privilegi di amministratore.
    static func disable(_ item: LoginItem) async -> (success: Bool, errorMessage: String?) {
        await Task.detached(priority: .userInitiated) {
            unload(item)

            if item.scope == .user {
                let failures = TrashService.moveToTrash([item.plistPath])
                if failures.isEmpty { return (true, nil) }
                if failures.contains(where: { UniversalAppThinner.isPermissionError($0.underlyingError) }) {
                    return disableElevated(item)
                }
                return (false, failures.first?.underlyingError.localizedDescription)
            } else {
                return disableElevated(item)
            }
        }.value
    }

    private static func unload(_ item: LoginItem) {
        let uid = getuid()
        _ = runProcess("/bin/launchctl", ["bootout", "gui/\(uid)/\(item.label)"])
    }

    private static func disableElevated(_ item: LoginItem) -> (success: Bool, errorMessage: String?) {
        let trashDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".Trash")
        let destination = trashDir.appendingPathComponent(item.plistPath.lastPathComponent)

        let scriptLines = [
            "mkdir -p \(ElevatedShell.shellQuoted(trashDir.path))",
            "mv -f \(ElevatedShell.shellQuoted(item.plistPath.path)) \(ElevatedShell.shellQuoted(destination.path))"
        ]
        let result = ElevatedShell.run(scriptLines)
        return (result.success, result.errorMessage)
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
