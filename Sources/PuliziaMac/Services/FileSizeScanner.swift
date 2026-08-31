import Foundation

/// Helper condiviso per calcolare la dimensione su disco di file e cartelle.
enum FileSizeScanner {
    /// Errore di permesso rilevato durante una scansione (tipicamente manca Full Disk Access).
    struct PermissionDenied: Error {
        let path: URL
    }

    /// Dimensione allocata su disco di un singolo file (non la dimensione logica).
    static func size(ofFile url: URL) throws -> Int64 {
        let values = try url.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey])
        return Int64(values.totalFileAllocatedSize ?? values.fileAllocatedSize ?? 0)
    }

    /// Dimensione totale ricorsiva di una cartella. Ignora i file che non è possibile leggere
    /// (permessi negati) senza far fallire l'intera scansione, ma segnala se la cartella radice
    /// stessa non è accessibile.
    static func size(ofDirectory url: URL, skipPackageDescendants: Bool = true) throws -> Int64 {
        let fm = FileManager.default
        var options: FileManager.DirectoryEnumerationOptions = []
        if skipPackageDescendants {
            options.insert(.skipsPackageDescendants)
        }
        guard let enumerator = fm.enumerator(
            at: url,
            includingPropertiesForKeys: [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey, .isDirectoryKey],
            options: options,
            errorHandler: nil
        ) else {
            throw PermissionDenied(path: url)
        }

        var total: Int64 = 0
        for entry in enumerator {
            guard let fileURL = entry as? URL else { continue }
            guard let values = try? fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey, .isDirectoryKey]) else {
                continue
            }
            if values.isDirectory == true { continue }
            total += Int64(values.totalFileAllocatedSize ?? values.fileAllocatedSize ?? 0)
        }
        return total
    }

    /// Elenca le voci di primo livello di una cartella (usato per elencare le sotto-cache per app).
    static func topLevelEntries(of directory: URL) -> [URL] {
        let fm = FileManager.default
        guard let entries = try? fm.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }
        return entries
    }
}
