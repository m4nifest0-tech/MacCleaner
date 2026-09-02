import Foundation

enum CleanableCategory: String, CaseIterable, Identifiable {
    case appCaches
    case logs
    case trash
    case developer
    case downloadsInstallers
    case mailAttachments

    var id: String { rawValue }

    /// Chiave nel dizionario di localizzazione: vedi `Localization.swift`.
    var titleKey: String { "category.\(rawValue)" }
}

struct CleanableItem: Identifiable, Hashable {
    let id: URL
    let name: String
    let path: URL
    let category: CleanableCategory
    var sizeBytes: Int64
    var isDirectory: Bool

    init(path: URL, category: CleanableCategory, sizeBytes: Int64, isDirectory: Bool) {
        self.id = path
        self.name = path.lastPathComponent
        self.path = path
        self.category = category
        self.sizeBytes = sizeBytes
        self.isDirectory = isDirectory
    }
}

extension Int64 {
    var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: self, countStyle: .file)
    }

    /// Calcolo binario (1024) come "Informazioni su questo Mac", a differenza di
    /// `formattedFileSize` (decimale, in stile Finder) usato per file e spazio su disco.
    var formattedMemorySize: String {
        ByteCountFormatter.string(fromByteCount: self, countStyle: .memory)
    }
}
