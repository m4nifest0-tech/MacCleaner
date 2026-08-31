import Foundation

struct LargeFile: Identifiable, Hashable {
    let id: URL
    let path: URL
    let sizeBytes: Int64

    init(path: URL, sizeBytes: Int64) {
        self.id = path
        self.path = path
        self.sizeBytes = sizeBytes
    }
}

enum LargeFileThreshold: Int64, CaseIterable, Identifiable {
    case oneHundredMB = 100_000_000
    case fiveHundredMB = 500_000_000
    case oneGB = 1_000_000_000
    case fiveGB = 5_000_000_000

    var id: Int64 { rawValue }
}
