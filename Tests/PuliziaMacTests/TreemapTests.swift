import Foundation
import Testing
@testable import PuliziaMac

struct TreemapTests {
    private func entry(_ name: String, _ size: Int64) -> DiskExplorerEntry {
        DiskExplorerEntry(path: URL(fileURLWithPath: "/tmp/\(name)"), sizeBytes: size, isDirectory: false)
    }

    @Test func producesOneRectPerEntry() {
        let entries = [entry("a", 100), entry("b", 200), entry("c", 300)]
        let rects = Treemap.layout(entries: entries, in: CGRect(x: 0, y: 0, width: 400, height: 300))
        #expect(rects.count == 3)
        #expect(Set(rects.map(\.id)) == Set(entries.map(\.id)))
    }

    @Test func totalAreaMatchesContainer() {
        let entries = [entry("a", 100), entry("b", 200), entry("c", 300), entry("d", 50)]
        let container = CGRect(x: 0, y: 0, width: 500, height: 400)
        let rects = Treemap.layout(entries: entries, in: container)
        let totalArea = rects.reduce(0.0) { $0 + $1.rect.width * $1.rect.height }
        let containerArea = container.width * container.height
        #expect(abs(totalArea - containerArea) < 1.0)
    }

    @Test func largerEntryGetsLargerArea() {
        let entries = [entry("small", 100), entry("big", 900)]
        let rects = Treemap.layout(entries: entries, in: CGRect(x: 0, y: 0, width: 400, height: 300))
        let small = rects.first { $0.entry.name == "small" }!
        let big = rects.first { $0.entry.name == "big" }!
        #expect(big.rect.width * big.rect.height > small.rect.width * small.rect.height)
    }

    @Test func emptyEntriesProduceNoRects() {
        #expect(Treemap.layout(entries: [], in: CGRect(x: 0, y: 0, width: 400, height: 300)).isEmpty)
    }

    @Test func degenerateContainerProducesNoRects() {
        let entries = [entry("a", 100)]
        #expect(Treemap.layout(entries: entries, in: .zero).isEmpty)
    }
}
