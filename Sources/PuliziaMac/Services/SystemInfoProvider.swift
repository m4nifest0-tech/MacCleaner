import Foundation
import Darwin

struct SystemInfo {
    let computerName: String
    let macOSVersion: String
    let modelIdentifier: String
}

enum SystemInfoProvider {
    static func current() -> SystemInfo {
        SystemInfo(
            computerName: Host.current().localizedName ?? "Mac",
            macOSVersion: ProcessInfo.processInfo.operatingSystemVersionString,
            modelIdentifier: modelIdentifier()
        )
    }

    private static func modelIdentifier() -> String {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        guard size > 0 else { return "Mac" }
        var buffer = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &buffer, &size, nil, 0)
        return String(cString: buffer)
    }
}
