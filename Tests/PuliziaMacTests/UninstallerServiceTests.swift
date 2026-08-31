import Foundation
import Testing
@testable import PuliziaMac

struct UninstallerServiceTests {
    @Test func includesKnownLocationsForBundleIdentifierAndName() {
        let home = URL(fileURLWithPath: "/Users/test")
        let paths = UninstallerService.candidatePaths(
            bundleIdentifier: "com.example.foo",
            appName: "Foo",
            home: home
        ).map(\.path)

        #expect(paths.contains("/Users/test/Library/Application Support/Foo"))
        #expect(paths.contains("/Users/test/Library/Caches/com.example.foo"))
        #expect(paths.contains("/Users/test/Library/Preferences/com.example.foo.plist"))
        #expect(paths.contains("/Users/test/Library/Saved Application State/com.example.foo.savedState"))
        #expect(paths.contains("/Users/test/Library/Containers/com.example.foo"))
    }

    @Test func doesNotIncludeBundleIdentifierPathsWhenNil() {
        let home = URL(fileURLWithPath: "/Users/test")
        let paths = UninstallerService.candidatePaths(bundleIdentifier: nil, appName: "Foo", home: home)
        #expect(!paths.contains { $0.path.contains("Preferences") })
        #expect(paths.contains { $0.path == "/Users/test/Library/Application Support/Foo" })
    }

    @Test func findsOnlyExistingLeftovers() async throws {
        let fm = FileManager.default
        let home = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fm.createDirectory(at: home.appendingPathComponent("Library/Application Support/Foo"), withIntermediateDirectories: true)
        try Data("hello".utf8).write(to: home.appendingPathComponent("Library/Application Support/Foo/settings.json"))
        defer { try? fm.removeItem(at: home) }

        let existing = UninstallerService.candidatePaths(bundleIdentifier: "com.example.foo", appName: "Foo", home: home)
            .filter { fm.fileExists(atPath: $0.path) }

        #expect(existing.count == 1)
        #expect(existing.first?.lastPathComponent == "Foo")
    }
}
