import Testing
@testable import PuliziaMac

struct MemoryInfoProviderTests {
    // Campione reale catturato da `vm_stat` su un Mac Apple Silicon (page size 16384).
    private static let sampleVMStatOutput = """
    Mach Virtual Memory Statistics: (page size of 16384 bytes)
    Pages free:                                     5578.
    Pages active:                                 270026.
    Pages inactive:                               270829.
    Pages speculative:                               103.
    Pages throttled:                                   0.
    Pages wired down:                             141237.
    Pages purgeable:                                9431.
    "Translation faults":                      351466984.
    Pages copy-on-write:                         5727324.
    Pages zero filled:                         299137493.
    Pages reactivated:                          54966678.
    Pages purged:                                6254053.
    File-backed pages:                            177747.
    Anonymous pages:                              363211.
    Pages stored in compressor:                   659453.
    Pages occupied by compressor:                 322098.
    Decompressions:                             36695052.
    Compressions:                               45877473.
    Pageins:                                    12830994.
    Pageouts:                                      64173.
    Swapins:                                       20655.
    Swapouts:                                     101888.
    """

    @Test func parsesRealVMStatSample() {
        let totalBytes: Int64 = 17_179_869_184
        let info = MemoryInfoProvider.parse(Self.sampleVMStatOutput, totalMemoryBytes: totalBytes)
        let pageSize: Int64 = 16384

        #expect(info?.totalBytes == totalBytes)
        #expect(info?.freeBytes == 5578 * pageSize)
        #expect(info?.activeBytes == 270026 * pageSize)
        #expect(info?.inactiveBytes == 270829 * pageSize)
        #expect(info?.wiredBytes == 141237 * pageSize)
        #expect(info?.compressedBytes == 322098 * pageSize)
    }

    @Test func usedBytesExcludesFreeAndInactive() {
        let info = MemoryInfo(
            totalBytes: 1000,
            freeBytes: 100,
            activeBytes: 300,
            inactiveBytes: 200,
            wiredBytes: 150,
            compressedBytes: 50
        )
        #expect(info.usedBytes == 500) // active + wired + compressed, not free/inactive
        #expect(info.usedFraction == 0.5)
    }

    @Test func returnsNilForUnrecognizedOutput() {
        #expect(MemoryInfoProvider.parse("not vm_stat output at all", totalMemoryBytes: 1000) == nil)
    }
}
