import Foundation

struct MemoryInfo {
    let totalBytes: Int64
    let freeBytes: Int64
    let activeBytes: Int64
    let inactiveBytes: Int64
    let wiredBytes: Int64
    let compressedBytes: Int64

    /// Coerente con quanto mostra Monitoraggio Attività: "usata" è ciò che non si
    /// libera da solo all'istante (attiva + wired + compressa). "Inattiva" è
    /// recuperabile ma non viene contata come occupata, dato che è proprio quella
    /// che l'azione "Libera memoria" prova a restituire.
    var usedBytes: Int64 { activeBytes + wiredBytes + compressedBytes }

    var usedFraction: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(usedBytes) / Double(totalBytes)
    }
}

enum MemoryInfoProvider {
    static func current() async -> MemoryInfo? {
        guard let output = await run("/usr/bin/vm_stat", []) else { return nil }
        let totalBytes = SystemInfoProvider.current().memoryBytes
        return parse(output, totalMemoryBytes: totalBytes)
    }

    static func parse(_ output: String, totalMemoryBytes: Int64) -> MemoryInfo? {
        guard let pageSize = pageSize(in: output),
              let free = pageCount(output, prefix: "Pages free:"),
              let active = pageCount(output, prefix: "Pages active:"),
              let inactive = pageCount(output, prefix: "Pages inactive:"),
              let wired = pageCount(output, prefix: "Pages wired down:"),
              let compressed = pageCount(output, prefix: "Pages occupied by compressor:") else {
            return nil
        }
        return MemoryInfo(
            totalBytes: totalMemoryBytes,
            freeBytes: free * pageSize,
            activeBytes: active * pageSize,
            inactiveBytes: inactive * pageSize,
            wiredBytes: wired * pageSize,
            compressedBytes: compressed * pageSize
        )
    }

    /// Es. "Mach Virtual Memory Statistics: (page size of 16384 bytes)" → 16384.
    private static func pageSize(in output: String) -> Int64? {
        guard let prefixRange = output.range(of: "page size of ") else { return nil }
        let afterPrefix = output[prefixRange.upperBound...]
        guard let bytesRange = afterPrefix.range(of: " bytes") else { return nil }
        let digits = afterPrefix[..<bytesRange.lowerBound].filter(\.isNumber)
        guard !digits.isEmpty else { return nil }
        return Int64(digits)
    }

    /// Es. "Pages wired down:                             153498." con prefisso
    /// "Pages wired down:" → 153498.
    private static func pageCount(_ output: String, prefix: String) -> Int64? {
        for rawLine in output.split(separator: "\n") {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard line.hasPrefix(prefix) else { continue }
            let digits = line.dropFirst(prefix.count).filter(\.isNumber)
            guard !digits.isEmpty else { return nil }
            return Int64(digits)
        }
        return nil
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
