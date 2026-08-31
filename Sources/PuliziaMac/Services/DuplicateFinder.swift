import Foundation
import CryptoKit

/// Trova file duplicati (stesso contenuto) in una o più cartelle scelte dall'utente.
/// Strategia: prima raggruppa per dimensione esatta (economico), poi conferma i soli
/// gruppi candidati calcolando l'hash SHA256 in streaming — evita di leggere per intero
/// file che non potranno mai essere duplicati.
enum DuplicateFinder {
    static func find(in directories: [URL], excludedFolders: [URL] = []) async -> [DuplicateGroup] {
        let candidates = await Task.detached(priority: .userInitiated) { () -> [Int64: [URL]] in
            var bySize: [Int64: [URL]] = [:]
            let fm = FileManager.default
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
                          let size = values.fileSize, size > 0 else { continue }
                    bySize[Int64(size), default: []].append(url)
                }
            }
            return bySize.filter { $0.value.count > 1 }
        }.value

        var groups: [DuplicateGroup] = []

        await withTaskGroup(of: [DuplicateGroup].self) { group in
            for (size, urls) in candidates {
                group.addTask {
                    hashAndGroup(urls, sizeBytes: size)
                }
            }
            for await partial in group {
                groups.append(contentsOf: partial)
            }
        }

        return groups.sorted { $0.reclaimableBytes > $1.reclaimableBytes }
    }

    private static func hashAndGroup(_ urls: [URL], sizeBytes: Int64) -> [DuplicateGroup] {
        var byHash: [String: [URL]] = [:]
        for url in urls {
            guard let digest = sha256(of: url) else { continue }
            byHash[digest, default: []].append(url)
        }
        return byHash.compactMap { hash, matchingURLs in
            guard matchingURLs.count > 1 else { return nil }
            let files = matchingURLs.map { DuplicateFile(path: $0, sizeBytes: sizeBytes) }
            return DuplicateGroup(id: hash, sizeBytes: sizeBytes, files: files)
        }
    }

    static func sha256(of url: URL) -> String? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }

        var hasher = SHA256()
        while true {
            guard let chunk = try? handle.read(upToCount: 1 * 1024 * 1024), !chunk.isEmpty else { break }
            hasher.update(data: chunk)
        }
        let digest = hasher.finalize()
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
