import Foundation
import Testing
@testable import PuliziaMac

struct DiskExplorerEntryTests {
    @Test func regularFolderIsNavigable() {
        let entry = DiskExplorerEntry(path: URL(fileURLWithPath: "/Users/test/Documents"), sizeBytes: 100, isDirectory: true)
        #expect(entry.isNavigable)
    }

    @Test func appBundleIsNotNavigable() {
        let entry = DiskExplorerEntry(path: URL(fileURLWithPath: "/Applications/Foo.app"), sizeBytes: 100, isDirectory: true)
        #expect(!entry.isNavigable)
    }

    @Test func plainFileIsNotNavigable() {
        let entry = DiskExplorerEntry(path: URL(fileURLWithPath: "/Users/test/file.txt"), sizeBytes: 100, isDirectory: false)
        #expect(!entry.isNavigable)
    }
}

struct DiskExplorerServiceTests {
    @Test func listsTopLevelEntriesWithSizesSortedDescending() async throws {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fm.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: root) }

        try Data(repeating: 0, count: 500).write(to: root.appendingPathComponent("small.bin"))
        let subfolder = root.appendingPathComponent("big-folder")
        try fm.createDirectory(at: subfolder, withIntermediateDirectories: true)
        try Data(repeating: 0, count: 5_000).write(to: subfolder.appendingPathComponent("inner.bin"))

        let entries = await DiskExplorerService.listEntries(in: root)

        #expect(entries.count == 2)
        #expect(entries.first?.name == "big-folder")
        #expect(entries.first?.isDirectory == true)
        #expect(entries.first!.sizeBytes > entries.last!.sizeBytes)
    }

    @Test func returnsEmptyForNonexistentDirectory() async {
        let entries = await DiskExplorerService.listEntries(in: URL(fileURLWithPath: "/nonexistent/\(UUID().uuidString)"))
        #expect(entries.isEmpty)
    }
}
