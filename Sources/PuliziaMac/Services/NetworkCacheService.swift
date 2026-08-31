import Foundation

/// Svuota la cache DNS di macOS. Richiede privilegi di amministratore (comandi
/// standard: `dscacheutil -flushcache` + `killall -HUP mDNSResponder`). Operazione
/// innocua e temporanea: la cache si ricostruisce da sola alle risoluzioni successive.
enum NetworkCacheService {
    static func flushDNSCache() async -> (success: Bool, errorMessage: String?) {
        await Task.detached(priority: .userInitiated) {
            let result = ElevatedShell.run(["dscacheutil -flushcache", "killall -HUP mDNSResponder"])
            return (result.success, result.errorMessage)
        }.value
    }
}
