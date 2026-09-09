import Testing
@testable import PuliziaMac

struct DiskHealthProviderTests {
    // Formato reale dell'output di `smartctl -a -d nvme` per il log page SMART/Health
    // NVMe (0x02), documentato pubblicamente da smartmontools.
    private static let sampleSmartctlOutput = """
    === START OF SMART DATA SECTION ===
    SMART overall-health self-assessment test result: PASSED

    SMART/Health Information (NVMe Log 0x02)
    Critical Warning:                  0x00
    Temperature:                       35 Celsius
    Available Spare:                   100%
    Available Spare Threshold:         10%
    Percentage Used:                   3%
    Data Units Read:                   12,345,678 [6.32 TB]
    Data Units Written:                 8,765,432 [4.48 TB]
    Host Read Commands:                123,456,789
    Host Write Commands:                98,765,432
    Power Cycles:                      567
    Power On Hours:                    1,234
    Unsafe Shutdowns:                  12
    Media and Data Integrity Errors:   0
    """

    @Test func parsesStandardNVMeSmartctlOutput() {
        let parsed = DiskHealthProvider.parseSmartctlOutput(Self.sampleSmartctlOutput)
        let expectedBytesWritten: Int64 = 8_765_432 * 512_000
        #expect(parsed?.temperature == 35)
        #expect(parsed?.percentageUsed == 3)
        #expect(parsed?.powerOnHours == 1234)
        #expect(parsed?.dataUnitsWrittenBytes == expectedBytesWritten)
    }

    @Test func returnsNilWhenNoRecognizedFieldsPresent() {
        #expect(DiskHealthProvider.parseSmartctlOutput("some unrelated output\nwith no smart fields") == nil)
    }

    @Test func smartStatusMapsKnownRawValues() {
        #expect(SMARTStatus(rawValue: "Verified") == .verified)
        #expect(SMARTStatus(rawValue: "Failing") == .failing)
        #expect(SMARTStatus(rawValue: "Not Supported") == .notSupported)
        #expect(SMARTStatus(rawValue: nil) == .unknown)
        #expect(SMARTStatus(rawValue: "Something Else") == .unknown)
    }

    @Test func healthLevelIsCriticalWhenSmartFailing() {
        let info = makeInfo(smartStatus: .failing)
        #expect(info.healthLevel == .critical)
    }

    @Test func healthLevelIsCriticalWhenWearVeryHigh() {
        let info = makeInfo(smartStatus: .verified, percentageUsed: 95)
        #expect(info.healthLevel == .critical)
    }

    @Test func healthLevelIsWarningWhenWearModeratelyHigh() {
        let info = makeInfo(smartStatus: .verified, percentageUsed: 75)
        #expect(info.healthLevel == .warning)
    }

    @Test func healthLevelIsWarningWhenSmartStatusUnknown() {
        let info = makeInfo(smartStatus: .unknown)
        #expect(info.healthLevel == .warning)
    }

    @Test func healthLevelIsGoodWhenAllVerifiedAndNoExtraData() {
        let info = makeInfo(smartStatus: .verified)
        #expect(info.healthLevel == .good)
        #expect(info.hasExtraSmartData == false)
    }

    private func makeInfo(
        smartStatus: SMARTStatus,
        percentageUsed: Int? = nil,
        temperature: Int? = nil
    ) -> DiskHealthInfo {
        DiskHealthInfo(
            modelName: "APPLE SSD TEST",
            capacityBytes: 256_000_000_000,
            smartStatus: smartStatus,
            trimSupported: true,
            availableBytes: 100_000_000_000,
            totalBytes: 256_000_000_000,
            temperatureCelsius: temperature,
            percentageUsed: percentageUsed,
            dataUnitsWrittenBytes: nil,
            powerOnHours: nil
        )
    }
}
