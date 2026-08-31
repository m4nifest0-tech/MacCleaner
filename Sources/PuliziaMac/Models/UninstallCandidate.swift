import Foundation

/// Un'app installata più gli eventuali file residui associati (preferenze, cache,
/// application support, log, ecc.) trovati per bundle identifier o nome.
struct LeftoverFile: Identifiable, Hashable {
    let id: URL
    let path: URL
    let sizeBytes: Int64

    init(path: URL, sizeBytes: Int64) {
        self.id = path
        self.path = path
        self.sizeBytes = sizeBytes
    }
}

struct UninstallCandidate: Identifiable, Hashable {
    let id: URL
    let app: AppBundleInfo
    var leftovers: [LeftoverFile]

    init(app: AppBundleInfo, leftovers: [LeftoverFile] = []) {
        self.id = app.id
        self.app = app
        self.leftovers = leftovers
    }

    var totalLeftoverSize: Int64 {
        leftovers.reduce(0) { $0 + $1.sizeBytes }
    }
}
