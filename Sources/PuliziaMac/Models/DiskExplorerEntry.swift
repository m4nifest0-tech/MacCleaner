import Foundation

struct DiskExplorerEntry: Identifiable, Hashable {
    let id: URL
    let path: URL
    let name: String
    let sizeBytes: Int64
    let isDirectory: Bool

    init(path: URL, sizeBytes: Int64, isDirectory: Bool) {
        self.id = path
        self.path = path
        self.name = path.lastPathComponent
        self.sizeBytes = sizeBytes
        self.isDirectory = isDirectory
    }

    /// Le cartelle "pacchetto" (app, bundle, framework…) si comportano come un unico
    /// file in Finder: ha senso vederne la dimensione, non navigarci dentro.
    private static let packageExtensions: Set<String> = ["app", "bundle", "framework", "plugin", "kext", "prefpane", "qlgenerator"]

    var isNavigable: Bool {
        isDirectory && !Self.packageExtensions.contains(path.pathExtension.lowercased())
    }
}
