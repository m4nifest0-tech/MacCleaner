import Testing
@testable import PuliziaMac

struct DiskOverviewTests {
    @Test func currentReturnsPlausibleValues() throws {
        let overview = try #require(DiskOverview.current())
        #expect(overview.totalBytes > 0)
        #expect(overview.usedBytes <= overview.totalBytes)
        #expect(overview.usedFraction >= 0 && overview.usedFraction <= 1)
    }

    @Test func usedFractionIsZeroWhenTotalIsZero() {
        let overview = DiskOverview(totalBytes: 0, freeBytes: 0)
        #expect(overview.usedFraction == 0)
    }
}
