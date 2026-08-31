import Foundation
import Testing
@testable import PuliziaMac

struct LargeFileFinderTests {
    @Test func findsOnlyFilesAtOrAboveThreshold() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let big = root.appendingPathComponent("big.bin")
        let small = root.appendingPathComponent("small.bin")
        try Data(repeating: 0, count: 2_000).write(to: big)
        try Data(repeating: 0, count: 100).write(to: small)

        let results = await LargeFileFinder.find(in: [root], minimumSize: 1_000)

        #expect(results.count == 1)
        #expect(results.first?.path.resolvingSymlinksInPath() == big.resolvingSymlinksInPath())
    }

    @Test func sortsResultsBySizeDescending() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        try Data(repeating: 0, count: 1_000).write(to: root.appendingPathComponent("a.bin"))
        try Data(repeating: 0, count: 3_000).write(to: root.appendingPathComponent("b.bin"))
        try Data(repeating: 0, count: 2_000).write(to: root.appendingPathComponent("c.bin"))

        let results = await LargeFileFinder.find(in: [root], minimumSize: 500)

        #expect(results.map(\.sizeBytes) == [3_000, 2_000, 1_000])
    }

    @Test func respectsExcludedFolders() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let excludedDir = root.appendingPathComponent("excluded")
        try FileManager.default.createDirectory(at: excludedDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        try Data(repeating: 0, count: 2_000).write(to: excludedDir.appendingPathComponent("big.bin"))
        try Data(repeating: 0, count: 2_000).write(to: root.appendingPathComponent("also-big.bin"))

        let results = await LargeFileFinder.find(in: [root], minimumSize: 1_000, excludedFolders: [excludedDir])

        #expect(results.count == 1)
        #expect(results.first?.path.lastPathComponent == "also-big.bin")
    }
}
