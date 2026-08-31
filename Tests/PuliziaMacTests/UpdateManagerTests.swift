import Foundation
import Testing
@testable import PuliziaMac

struct UpdateManagerTests {
    @Test func parsesMasOutdatedLines() {
        let output = """
        409183694 Keynote (12.2 -> 13.0)
        408981434 iMovie (10.3 -> 10.4)
        """
        let items = UpdateManager.parseMasOutdated(output)

        #expect(items.count == 2)
        #expect(items[0].id == "mas:409183694")
        #expect(items[0].name == "Keynote")
        #expect(items[0].installedVersion == "12.2")
        #expect(items[0].availableVersion == "13.0")
        #expect(items[1].name == "iMovie")
    }

    @Test func returnsEmptyForBlankOutput() {
        #expect(UpdateManager.parseMasOutdated("").isEmpty)
        #expect(UpdateManager.parseMasOutdated("\n\n").isEmpty)
    }

    @Test func ignoresMalformedLines() {
        let items = UpdateManager.parseMasOutdated("questa riga non ha il formato atteso")
        #expect(items.isEmpty)
    }
}
