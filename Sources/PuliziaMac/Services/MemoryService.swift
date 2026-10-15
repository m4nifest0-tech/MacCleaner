import Foundation

/// Richiede al sistema di liberare le pagine di memoria riutilizzabili (cache su
/// disco, gestita dall'Unified Buffer Cache) tramite `purge`. Richiede privilegi di
/// amministratore — verificato che fallisce con "Operation not permitted" da utente
/// normale. L'effetto varia in base a cosa è davvero riutilizzabile in quel momento:
/// non è garantito un grande calo della memoria "attiva" o "wired".
enum MemoryService {
    static func purgeInactiveMemory() async -> (success: Bool, errorMessage: String?) {
        await Task.detached(priority: .userInitiated) {
            let result = ElevatedShell.run(["/usr/sbin/purge"])
            return (result.success, result.errorMessage)
        }.value
    }
}
