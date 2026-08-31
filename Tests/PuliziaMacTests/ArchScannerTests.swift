import Foundation
import Testing
@testable import PuliziaMac

struct ArchScannerTests {
    @Test func parsesUniversalBinary() {
        let output = "Architectures in the fat file: /Applications/Foo.app/Contents/MacOS/Foo are: x86_64 arm64\n"
        #expect(ArchScanner.parseLipoOutput(output) == ["x86_64", "arm64"])
    }

    @Test func parsesSingleArchitectureBinary() {
        let output = "Non-fat file: /Applications/Foo.app/Contents/MacOS/Foo is architecture: x86_64\n"
        #expect(ArchScanner.parseLipoOutput(output) == ["x86_64"])
    }

    @Test func parsesArm64OnlyBinary() {
        let output = "Non-fat file: /Applications/Foo.app/Contents/MacOS/Foo is architecture: arm64\n"
        #expect(ArchScanner.parseLipoOutput(output) == ["arm64"])
    }

    @Test func returnsNilForUnrecognizedOutput() {
        #expect(ArchScanner.parseLipoOutput("qualcosa di inatteso") == nil)
    }

    @Test func fileFallbackDetectsArchitectures() {
        let output = "Foo: Mach-O universal binary with 2 architectures: [x86_64:Mach-O 64-bit executable x86_64] [arm64:Mach-O 64-bit executable arm64]"
        let archs = ArchScanner.parseFileOutput(output)
        #expect(archs?.sorted() == ["arm64", "x86_64"])
    }

    @Test func isIntelOnlyDetection() {
        let intelOnly = AppBundleInfo(bundleURL: URL(fileURLWithPath: "/Applications/Old.app"), bundleIdentifier: "com.example.old", version: "1.0", architectures: ["x86_64"], sizeBytes: 100)
        let universal = AppBundleInfo(bundleURL: URL(fileURLWithPath: "/Applications/New.app"), bundleIdentifier: "com.example.new", version: "2.0", architectures: ["x86_64", "arm64"], sizeBytes: 100)
        #expect(intelOnly.isIntelOnly)
        #expect(!universal.isIntelOnly)
    }
}
