import Foundation

/// Cerca i file più pesanti in una o più cartelle scelte dall'utente, sopra una soglia
/// di dimensione. A differenza del rilevamento duplicati, qui non serve calcolare hash:
/// basta la dimensione riportata dal filesystem.
enum LargeFileFinder {
    static func find(in directories: [URL], minimumSize: Int64, excludedFolders: [URL] = []) async -> [LargeFile] {
        await Task.detached(priority: .userInitiated) {
            let fm = FileManager.default
            var results: [LargeFile] = []

            for directory in directories {
                guard let enumerator = fm.enumerator(
                    at: directory,
                    includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
                    options: [.skipsHiddenFiles, .skipsPackageDescendants]
                ) else { continue }

                while let url = enumerator.nextObject() as? URL {
                    if !excludedFolders.isEmpty, ExclusionMatcher.isExcluded(url, excludedFolders: excludedFolders) {
                        if url.hasDirectoryPath { enumerator.skipDescendants() }
                        continue
                    }
                    guard let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]),
                          values.isRegularFile == true,
                          let size = values.fileSize, Int64(size) >= minimumSize else { continue }
                    results.append(LargeFile(path: url, sizeBytes: Int64(size)))
                }
            }

            return results.sorted { $0.sizeBytes > $1.sizeBytes }
        }.value
    }
}
