import Foundation
import Testing
@testable import PuliziaMac

struct StatsStoreTests {
    private func freshDefaults() -> UserDefaults {
        UserDefaults(suiteName: "PuliziaMacTests.\(UUID().uuidString)")!
    }

    @Test func startsAtZero() {
        let store = StatsStore(defaults: freshDefaults())
        #expect(store.totalBytesFreed == 0)
    }

    @Test func accumulatesAcrossCalls() {
        let store = StatsStore(defaults: freshDefaults())
        store.recordFreed(1_000)
        store.recordFreed(2_500)
        #expect(store.totalBytesFreed == 3_500)
    }

    @Test func ignoresZeroAndNegativeValues() {
        let store = StatsStore(defaults: freshDefaults())
        store.recordFreed(0)
        store.recordFreed(-100)
        #expect(store.totalBytesFreed == 0)
    }

    @Test func persistsAcrossInstances() {
        let defaults = freshDefaults()
        let first = StatsStore(defaults: defaults)
        first.recordFreed(42_000)

        let second = StatsStore(defaults: defaults)
        #expect(second.totalBytesFreed == 42_000)
    }
}
