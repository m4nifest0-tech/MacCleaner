import Foundation
import Testing
@testable import PuliziaMac

struct UniversalAppThinnerTests {
    @Test func detectsFatMachOMagic32() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let file = root.appendingPathComponent("fat32")
        var bytes: [UInt8] = [0xca, 0xfe, 0xba, 0xbe]
        bytes.append(contentsOf: Array(repeating: 0, count: 60))
        try Data(bytes).write(to: file)

        #expect(UniversalAppThinner.hasMachOFatMagic(file))
    }

    @Test func detectsFatMachOMagic64() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let file = root.appendingPathComponent("fat64")
        var bytes: [UInt8] = [0xca, 0xfe, 0xba, 0xbf]
        bytes.append(contentsOf: Array(repeating: 0, count: 60))
        try Data(bytes).write(to: file)

        #expect(UniversalAppThinner.hasMachOFatMagic(file))
    }

    @Test func rejectsNonMachOFile() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let file = root.appendingPathComponent("plain.txt")
        try Data("non è un binario Mach-O".utf8).write(to: file)

        #expect(!UniversalAppThinner.hasMachOFatMagic(file))
    }

    @Test func isMacAppStoreAppDetectsReceipt() throws {
        let fm = FileManager.default
        let appURL = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".app")
        try fm.createDirectory(at: appURL.appendingPathComponent("Contents/_MASReceipt"), withIntermediateDirectories: true)
        try Data("receipt".utf8).write(to: appURL.appendingPathComponent("Contents/_MASReceipt/receipt"))
        defer { try? fm.removeItem(at: appURL) }

        let app = AppBundleInfo(bundleURL: appURL, bundleIdentifier: "com.example.mas", version: "1.0", architectures: ["arm64", "x86_64"], sizeBytes: 100)
        #expect(app.isMacAppStoreApp)
        #expect(app.isUniversal)
    }

    @Test func shellQuotedEscapesSingleQuotesAndSpaces() {
        let quoted = UniversalAppThinner.shellQuoted("/Applications/App With 'Quotes'.app")
        #expect(quoted == "'/Applications/App With '\\''Quotes'\\''.app'")

        // Verifica che lo shell interpreti davvero il valore quotato come un unico argomento.
        let script = "printf '%s' \(quoted)"
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", script]
        let pipe = Pipe()
        process.standardOutput = pipe
        try? process.run()
        process.waitUntilExit()
        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)
        #expect(output == "/Applications/App With 'Quotes'.app")
    }

    @Test func appleScriptQuotedEscapesBackslashesAndDoubleQuotes() {
        let quoted = UniversalAppThinner.appleScriptQuoted(#"say "hi" \ done"#)
        #expect(quoted == #""say \"hi\" \\ done""#)
    }

    @Test func isPermissionErrorDetectsNoPermissionCode() {
        let error = NSError(domain: NSCocoaErrorDomain, code: NSFileWriteNoPermissionError)
        #expect(UniversalAppThinner.isPermissionError(error))
    }

    @Test func isPermissionErrorDetectsLocalizedPermissionMessage() {
        let error = NSError(domain: NSCocoaErrorDomain, code: 999, userInfo: [
            NSLocalizedDescriptionKey: "You don't have permission to save the file \"X\" in the folder \"MacOS\"."
        ])
        #expect(UniversalAppThinner.isPermissionError(error))
    }

    @Test func isPermissionErrorRejectsUnrelatedError() {
        let error = NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError)
        #expect(!UniversalAppThinner.isPermissionError(error))
    }

    @Test func isAppManagementErrorDetectsOperationNotPermitted() {
        #expect(UniversalAppThinner.isAppManagementError("lipo: can't create output file: ... (Operation not permitted)"))
        #expect(!UniversalAppThinner.isAppManagementError("No such file or directory"))
    }

    @Test func isUniversalRequiresBothArchitectures() {
        let intelOnly = AppBundleInfo(bundleURL: URL(fileURLWithPath: "/Applications/A.app"), bundleIdentifier: nil, version: nil, architectures: ["x86_64"], sizeBytes: 1)
        let armOnly = AppBundleInfo(bundleURL: URL(fileURLWithPath: "/Applications/B.app"), bundleIdentifier: nil, version: nil, architectures: ["arm64"], sizeBytes: 1)
        let universal = AppBundleInfo(bundleURL: URL(fileURLWithPath: "/Applications/C.app"), bundleIdentifier: nil, version: nil, architectures: ["arm64", "x86_64"], sizeBytes: 1)

        #expect(!intelOnly.isUniversal)
        #expect(!armOnly.isUniversal)
        #expect(universal.isUniversal)
    }
}
