import Testing
@testable import PuliziaMac

struct SystemInfoProviderTests {
    @Test func returnsPlausibleValues() {
        let info = SystemInfoProvider.current()
        #expect(!info.computerName.isEmpty)
        #expect(!info.macOSVersion.isEmpty)
        #expect(!info.modelIdentifier.isEmpty)
        #expect(info.modelIdentifier != "Mac", "Su questa macchina sysctlbyname dovrebbe risolvere un vero identificativo modello")
        #expect(!info.processorName.isEmpty)
        #expect(info.totalCores > 0)
        #expect(info.memoryBytes > 0)
    }
}
