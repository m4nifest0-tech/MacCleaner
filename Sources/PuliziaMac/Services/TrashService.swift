import Foundation

/// Punto unico per spostare elementi nel Cestino. Non cancella mai in modo permanente:
/// ogni operazione è reversibile dall'utente tramite il Cestino di macOS.
enum TrashService {
    struct Failure: Identifiable {
        let id = UUID()
        let path: URL
        let underlyingError: Error
    }

    /// Sposta i percorsi indicati nel Cestino. Ritorna gli eventuali fallimenti invece di
    /// interrompere l'intera operazione al primo errore, così l'utente vede cosa non è
    /// riuscito a spostare (es. permessi mancanti) e cosa invece è stato ripulito.
    static func moveToTrash(_ paths: [URL]) -> [Failure] {
        var failures: [Failure] = []
        for path in paths {
            do {
                try FileManager.default.trashItem(at: path, resultingItemURL: nil)
            } catch {
                failures.append(Failure(path: path, underlyingError: error))
            }
        }
        return failures
    }
}
