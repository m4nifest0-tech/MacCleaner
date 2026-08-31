import Foundation

struct DiskOverview {
    let totalBytes: Int64
    let freeBytes: Int64

    var usedBytes: Int64 { max(totalBytes - freeBytes, 0) }
    var usedFraction: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(usedBytes) / Double(totalBytes)
    }

    static func current() -> DiskOverview? {
        let root = URL(fileURLWithPath: "/")
        guard let values = try? root.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey]),
              let total = values.volumeTotalCapacity else { return nil }
        let free = values.volumeAvailableCapacityForImportantUsage ?? 0
        return DiskOverview(totalBytes: Int64(total), freeBytes: free)
    }
}
