import Foundation
import Testing
@testable import PuliziaMac

struct ExclusionMatcherTests {
    @Test func excludesExactFolder() {
        let excluded = [URL(fileURLWithPath: "/Users/test/Library/Caches/com.example.app")]
        #expect(ExclusionMatcher.isExcluded(URL(fileURLWithPath: "/Users/test/Library/Caches/com.example.app"), excludedFolders: excluded))
    }

    @Test func excludesFilesInsideExcludedFolder() {
        let excluded = [URL(fileURLWithPath: "/Users/test/Documents/Project")]
        #expect(ExclusionMatcher.isExcluded(URL(fileURLWithPath: "/Users/test/Documents/Project/notes.txt"), excludedFolders: excluded))
    }

    @Test func doesNotExcludeUnrelatedSiblingWithSharedPrefix() {
        let excluded = [URL(fileURLWithPath: "/Users/test/Documents/Project")]
        #expect(!ExclusionMatcher.isExcluded(URL(fileURLWithPath: "/Users/test/Documents/ProjectX/file.txt"), excludedFolders: excluded))
    }

    @Test func doesNotExcludeWhenNoMatch() {
        let excluded = [URL(fileURLWithPath: "/Users/test/Downloads")]
        #expect(!ExclusionMatcher.isExcluded(URL(fileURLWithPath: "/Users/test/Documents/file.txt"), excludedFolders: excluded))
    }
}

struct ExclusionStoreTests {
    private func freshDefaults() -> UserDefaults {
        UserDefaults(suiteName: "PuliziaMacTests.\(UUID().uuidString)")!
    }

    @Test func addAndRemovePersist() {
        let defaults = freshDefaults()
        let store = ExclusionStore(defaults: defaults)
        let folder = URL(fileURLWithPath: "/Users/test/Documents/Secret")

        store.add(folder)
        #expect(store.excludedFolders.contains(folder))

        let reloaded = ExclusionStore(defaults: defaults)
        #expect(reloaded.excludedFolders.contains(folder))

        store.remove(folder)
        #expect(!store.excludedFolders.contains(folder))
    }

    @Test func addingSameFolderTwiceDoesNotDuplicate() {
        let store = ExclusionStore(defaults: freshDefaults())
        let folder = URL(fileURLWithPath: "/Users/test/Documents/Secret")
        store.add(folder)
        store.add(folder)
        #expect(store.excludedFolders.count == 1)
    }

    @Test func isExcludedReflectsStoredFolders() {
        let store = ExclusionStore(defaults: freshDefaults())
        let folder = URL(fileURLWithPath: "/Users/test/Documents/Secret")
        store.add(folder)
        #expect(store.isExcluded(folder.appendingPathComponent("file.txt")))
        #expect(!store.isExcluded(URL(fileURLWithPath: "/Users/test/Documents/Other/file.txt")))
    }
}
