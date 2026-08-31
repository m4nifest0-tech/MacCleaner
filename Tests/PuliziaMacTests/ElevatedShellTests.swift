import Foundation
import Testing
@testable import PuliziaMac

struct ElevatedShellTests {
    @Test func shellQuotedEscapesSingleQuotesAndSpaces() {
        let quoted = ElevatedShell.shellQuoted("/tmp/App With 'Quotes'.plist")
        #expect(quoted == "'/tmp/App With '\\''Quotes'\\''.plist'")

        let script = "printf '%s' \(quoted)"
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", script]
        let pipe = Pipe()
        process.standardOutput = pipe
        try? process.run()
        process.waitUntilExit()
        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)
        #expect(output == "/tmp/App With 'Quotes'.plist")
    }

    @Test func appleScriptQuotedEscapesBackslashesAndDoubleQuotes() {
        let quoted = ElevatedShell.appleScriptQuoted(#"say "hi" \ done"#)
        #expect(quoted == #""say \"hi\" \\ done""#)
    }
}
