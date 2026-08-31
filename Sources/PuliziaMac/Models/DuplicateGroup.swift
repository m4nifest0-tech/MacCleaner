import Foundation

struct DuplicateFile: Identifiable, Hashable {
    let id: URL
    let path: URL
    let sizeBytes: Int64

    init(path: URL, sizeBytes: Int64) {
        self.id = path
        self.path = path
        self.sizeBytes = sizeBytes
    }
}

struct DuplicateGroup: Identifiable, Hashable {
    let id: String // hash del contenuto
    let sizeBytes: Int64
    let files: [DuplicateFile]

    /// Spazio recuperabile se si tengono tutte le copie tranne una.
    var reclaimableBytes: Int64 {
        sizeBytes * Int64(max(files.count - 1, 0))
    }
}
