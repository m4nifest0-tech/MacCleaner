import Foundation
import Testing
@testable import PuliziaMac

struct DuplicateFinderTests {
    @Test func findsIdenticalFilesAcrossSubfolders() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let content = Data("contenuto duplicato di prova".utf8)
        let uniqueContent = Data("contenuto diverso".utf8)

        let fileA = root.appendingPathComponent("a.txt")
        let fileB = root.appendingPathComponent("sub/b.txt")
        let fileC = root.appendingPathComponent("c.txt")
        try FileManager.default.createDirectory(at: fileB.deletingLastPathComponent(), withIntermediateDirectories: true)
        try content.write(to: fileA)
        try content.write(to: fileB)
        try uniqueContent.write(to: fileC)

        let groups = await DuplicateFinder.find(in: [root])

        #expect(groups.count == 1)
        #expect(groups.first?.files.count == 2)
        let foundPaths = Set((groups.first?.files.map(\.path) ?? []).map { $0.resolvingSymlinksInPath() })
        #expect(foundPaths == Set([fileA, fileB].map { $0.resolvingSymlinksInPath() }))
    }

    @Test func noDuplicatesWhenAllFilesDiffer() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        try Data("uno".utf8).write(to: root.appendingPathComponent("1.txt"))
        try Data("due".utf8).write(to: root.appendingPathComponent("2.txt"))

        let groups = await DuplicateFinder.find(in: [root])
        #expect(groups.isEmpty)
    }

    @Test func sha256IsStableForSameContent() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let file1 = root.appendingPathComponent("1.bin")
        let file2 = root.appendingPathComponent("2.bin")
        let data = Data(repeating: 0x42, count: 5 * 1024 * 1024) // forza più chunk da 1MB
        try data.write(to: file1)
        try data.write(to: file2)

        #expect(DuplicateFinder.sha256(of: file1) == DuplicateFinder.sha256(of: file2))
    }
}
