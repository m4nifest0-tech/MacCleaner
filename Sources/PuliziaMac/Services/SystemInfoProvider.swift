import Foundation
import Darwin
import IOKit.ps
import SystemConfiguration

struct SystemInfo {
    let computerName: String
    let macOSVersion: String
    let modelIdentifier: String
    let processorName: String
    let performanceCores: Int
    let efficiencyCores: Int
    let totalCores: Int
    let memoryBytes: Int64
    let batteryPercentage: Int?
    let isCharging: Bool
    let networkDescription: String?
}

enum SystemInfoProvider {
    static func current() -> SystemInfo {
        let battery = batteryInfo()
        return SystemInfo(
            computerName: Host.current().localizedName ?? "Mac",
            macOSVersion: ProcessInfo.processInfo.operatingSystemVersionString,
            modelIdentifier: modelIdentifier(),
            processorName: sysctlString("machdep.cpu.brand_string") ?? modelIdentifier(),
            performanceCores: sysctlInt("hw.perflevel0.physicalcpu"),
            efficiencyCores: sysctlInt("hw.perflevel1.physicalcpu"),
            totalCores: sysctlInt("hw.logicalcpu"),
            memoryBytes: Int64(sysctlInt("hw.memsize")),
            batteryPercentage: battery?.percentage,
            isCharging: battery?.isCharging ?? false,
            networkDescription: networkDescription()
        )
    }

    private static func modelIdentifier() -> String {
        sysctlString("hw.model") ?? "Mac"
    }

    private static func sysctlString(_ name: String) -> String? {
        var size = 0
        guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 0 else { return nil }
        var buffer = [CChar](repeating: 0, count: size)
        guard sysctlbyname(name, &buffer, &size, nil, 0) == 0 else { return nil }
        return String(cString: buffer)
    }

    private static func sysctlInt(_ name: String) -> Int {
        var value: Int64 = 0
        var size = MemoryLayout<Int64>.size
        guard sysctlbyname(name, &value, &size, nil, 0) == 0 else { return 0 }
        return Int(value)
    }

    private static func batteryInfo() -> (percentage: Int, isCharging: Bool)? {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              let source = sources.first,
              let info = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any],
              let capacity = info[kIOPSCurrentCapacityKey] as? Int else {
            return nil
        }
        let isCharging = (info[kIOPSPowerSourceStateKey] as? String) == kIOPSACPowerValue
        return (capacity, isCharging)
    }

    private static func networkDescription() -> String? {
        guard let store = SCDynamicStoreCreate(nil, "PuliziaMac" as CFString, nil, nil),
              let global = SCDynamicStoreCopyValue(store, "State:/Network/Global/IPv4" as CFString) as? [String: Any],
              let bsdName = global["PrimaryInterface"] as? String else {
            return nil
        }

        let displayName = interfaceDisplayName(bsdName: bsdName) ?? bsdName
        guard let address = ipv4Address(for: bsdName) else { return displayName }
        return "\(displayName) · \(address)"
    }

    private static func interfaceDisplayName(bsdName: String) -> String? {
        guard let interfaces = SCNetworkInterfaceCopyAll() as? [SCNetworkInterface] else { return nil }
        for interface in interfaces where SCNetworkInterfaceGetBSDName(interface) as String? == bsdName {
            return SCNetworkInterfaceGetLocalizedDisplayName(interface) as String?
        }
        return nil
    }

    private static func ipv4Address(for bsdName: String) -> String? {
        var ifaddrPtr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddrPtr) == 0, let firstAddr = ifaddrPtr else { return nil }
        defer { freeifaddrs(ifaddrPtr) }

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ptr.pointee
            guard String(cString: interface.ifa_name) == bsdName,
                  let addr = interface.ifa_addr,
                  addr.pointee.sa_family == UInt8(AF_INET) else { continue }

            var hostBuffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            getnameinfo(addr, socklen_t(addr.pointee.sa_len), &hostBuffer, socklen_t(hostBuffer.count), nil, 0, NI_NUMERICHOST)
            return String(cString: hostBuffer)
        }
        return nil
    }
}
