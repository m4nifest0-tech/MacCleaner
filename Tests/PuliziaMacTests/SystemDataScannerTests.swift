import Testing
@testable import PuliziaMac

struct SystemDataScannerTests {
    @Test func parsesEmptySnapshotList() {
        let output = "Snapshots for disk /:\n"
        #expect(SystemDataScanner.parseSnapshotList(output).isEmpty)
    }

    @Test func parsesSingleSnapshotWithDate() {
        let output = "Snapshots for disk /:\ncom.apple.TimeMachine.2026-09-09-151713.local\n"
        let snapshots = SystemDataScanner.parseSnapshotList(output)
        #expect(snapshots.count == 1)
        #expect(snapshots[0].id == "2026-09-09-151713")
        #expect(snapshots[0].date != nil)
    }

    @Test func parsesMultipleSnapshotsIgnoringHeader() {
        let output = """
        Snapshots for disk /:
        com.apple.TimeMachine.2026-01-15-121500.local
        com.apple.TimeMachine.2026-01-16-093000.local
        """
        let snapshots = SystemDataScanner.parseSnapshotList(output)
        #expect(snapshots.count == 2)
        #expect(snapshots.map(\.id) == ["2026-01-15-121500", "2026-01-16-093000"])
    }

    @Test func snapshotWithUnparsableDateStillReturnedWithNilDate() {
        let output = "com.apple.TimeMachine.not-a-date.local"
        let snapshots = SystemDataScanner.parseSnapshotList(output)
        #expect(snapshots.count == 1)
        #expect(snapshots[0].date == nil)
    }
}
