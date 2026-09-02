import Testing
@testable import PuliziaMac

struct SystemInfoProviderTests {
    @Test func returnsPlausibleValues() {
        let info = SystemInfoProvider.current()
        #expect(!info.computerName.isEmpty)
        #expect(!info.macOSVersion.isEmpty)
        #expect(!info.modelIdentifier.isEmpty)
        #expect(info.modelIdentifier != "Mac", "Su questa macchina sysctlbyname dovrebbe risolvere un vero identificativo modello")
    }
}
