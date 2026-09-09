import Foundation

enum SMARTStatus: Equatable {
    case verified
    case failing
    case notSupported
    case unknown

    init(rawValue: String?) {
        switch rawValue?.lowercased() {
        case "verified": self = .verified
        case "failing", "failing now": self = .failing
        case "not supported", "notsupported": self = .notSupported
        default: self = .unknown
        }
    }
}

/// Livello del semaforo salute SSD: dipende dallo stato SMART e, quando disponibili,
/// da percentuale di usura e temperatura — non dallo spazio libero, che è un dato
/// informativo a parte in questa stessa schermata, non un indicatore di salute del disco.
enum DiskHealthLevel {
    case good, warning, critical
}

struct DiskHealthInfo {
    let modelName: String
    let capacityBytes: Int64
    let smartStatus: SMARTStatus
    let trimSupported: Bool?
    let availableBytes: Int64
    let totalBytes: Int64

    /// Questi quattro campi vengono da `smartctl` (smartmontools), non installato di
    /// default: restano `nil` se non è presente sul sistema o se non riesce a leggere
    /// il dispositivo — cosa attesa sull'SSD interno dei Mac Apple Silicon, che usa
    /// un'interconnessione proprietaria ("Apple Fabric") non NVMe standard.
    let temperatureCelsius: Int?
    let percentageUsed: Int?
    let dataUnitsWrittenBytes: Int64?
    let powerOnHours: Int?

    var hasExtraSmartData: Bool {
        temperatureCelsius != nil || percentageUsed != nil || dataUnitsWrittenBytes != nil || powerOnHours != nil
    }

    var healthLevel: DiskHealthLevel {
        if smartStatus == .failing { return .critical }
        if let percentageUsed {
            if percentageUsed >= 90 { return .critical }
            if percentageUsed >= 70 { return .warning }
        }
        if let temperatureCelsius {
            if temperatureCelsius >= 70 { return .critical }
            if temperatureCelsius >= 60 { return .warning }
        }
        if smartStatus == .notSupported || smartStatus == .unknown { return .warning }
        return .good
    }
}

enum DiskHealthProvider {
    static func current() async -> DiskHealthInfo? {
        guard let nvme = await readNVMeInfo() else { return nil }
        let disk = DiskOverview.current()
        let extra = await readSmartctlExtra(bsdName: nvme.bsdName)

        return DiskHealthInfo(
            modelName: nvme.deviceModel,
            capacityBytes: nvme.sizeInBytes,
            smartStatus: SMARTStatus(rawValue: nvme.smartStatus),
            trimSupported: nvme.trimSupport,
            availableBytes: disk?.freeBytes ?? 0,
            totalBytes: disk?.totalBytes ?? nvme.sizeInBytes,
            temperatureCelsius: extra?.temperature,
            percentageUsed: extra?.percentageUsed,
            dataUnitsWrittenBytes: extra?.dataUnitsWrittenBytes,
            powerOnHours: extra?.powerOnHours
        )
    }

    // MARK: - NVMe info via system_profiler (pubblico, sempre disponibile)

    private struct NVMeEntry: Decodable {
        let _name: String
        let bsd_name: String
        let device_model: String?
        let size_in_bytes: Int64
        let smart_status: String?
        let spnvme_trim_support: String?
    }
    private struct NVMeDataType: Decodable {
        let _items: [NVMeEntry]
    }
    private struct NVMeRoot: Decodable {
        let SPNVMeDataType: [NVMeDataType]
    }

    private static func readNVMeInfo() async -> (bsdName: String, deviceModel: String, sizeInBytes: Int64, smartStatus: String?, trimSupport: Bool?)? {
        guard let output = await run("/usr/sbin/system_profiler", ["SPNVMeDataType", "-json"]),
              let data = output.data(using: .utf8),
              let parsed = try? JSONDecoder().decode(NVMeRoot.self, from: data),
              let entry = parsed.SPNVMeDataType.first?._items.first else {
            return nil
        }
        return (
            entry.bsd_name,
            entry.device_model ?? entry._name,
            entry.size_in_bytes,
            entry.smart_status,
            entry.spnvme_trim_support?.lowercased() == "yes"
        )
    }

    // MARK: - Dati estesi via smartctl (opzionale, solo se installato)

    static func locateSmartctl() -> String? {
        let candidates = ["/opt/homebrew/bin/smartctl", "/usr/local/bin/smartctl"]
        return candidates.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    private static func readSmartctlExtra(bsdName: String) async -> (temperature: Int?, percentageUsed: Int?, dataUnitsWrittenBytes: Int64?, powerOnHours: Int?)? {
        guard let smartctlPath = locateSmartctl() else { return nil }
        guard let output = await run(smartctlPath, ["-a", "-d", "nvme", "/dev/\(bsdName)"]) else { return nil }
        return parseSmartctlOutput(output)
    }

    /// Estrae i campi standard del log page "SMART/Health" NVMe dall'output testuale
    /// di `smartctl -a`. "Data Units Written" è in unità da 512.000 byte per specifica
    /// NVMe 1.x, da qui il fattore di conversione in byte totali scritti (TBW).
    static func parseSmartctlOutput(_ output: String) -> (temperature: Int?, percentageUsed: Int?, dataUnitsWrittenBytes: Int64?, powerOnHours: Int?)? {
        var temperature: Int?
        var percentageUsed: Int?
        var dataUnitsWrittenBytes: Int64?
        var powerOnHours: Int?

        for rawLine in output.split(separator: "\n") {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("Temperature:") {
                temperature = leadingNumber(afterColonIn: line).map(Int.init)
            } else if line.hasPrefix("Percentage Used:") {
                percentageUsed = leadingNumber(afterColonIn: line).map(Int.init)
            } else if line.hasPrefix("Data Units Written:") {
                dataUnitsWrittenBytes = leadingNumber(afterColonIn: line).map { $0 * 512_000 }
            } else if line.hasPrefix("Power On Hours:") {
                powerOnHours = leadingNumber(afterColonIn: line).map(Int.init)
            }
        }

        guard temperature != nil || percentageUsed != nil || dataUnitsWrittenBytes != nil || powerOnHours != nil else {
            return nil
        }
        return (temperature, percentageUsed, dataUnitsWrittenBytes, powerOnHours)
    }

    /// Es. "Data Units Written:                 12,345,678 [6.32 TB]" → 12345678
    /// (taglia alla prima "[", poi rimuove le virgole delle migliaia).
    private static func leadingNumber(afterColonIn line: String) -> Int64? {
        guard let colonIndex = line.firstIndex(of: ":") else { return nil }
        var valuePart = line[line.index(after: colonIndex)...]
        if let bracketIndex = valuePart.firstIndex(of: "[") {
            valuePart = valuePart[..<bracketIndex]
        }
        let digitsOnly = valuePart.filter(\.isNumber)
        guard !digitsOnly.isEmpty else { return nil }
        return Int64(digitsOnly)
    }

    private static func run(_ launchPath: String, _ arguments: [String]) async -> String? {
        await withCheckedContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: launchPath)
            process.arguments = arguments

            let outPipe = Pipe()
            process.standardOutput = outPipe
            process.standardError = Pipe()

            process.terminationHandler = { proc in
                let data = outPipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8)
                continuation.resume(returning: proc.terminationStatus == 0 ? (output ?? "") : nil)
            }

            do {
                try process.run()
            } catch {
                continuation.resume(returning: nil)
            }
        }
    }
}
