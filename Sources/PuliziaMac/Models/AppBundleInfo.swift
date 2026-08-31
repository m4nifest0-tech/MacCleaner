import Foundation

struct AppBundleInfo: Identifiable, Hashable {
    let id: URL
    let name: String
    let bundleIdentifier: String?
    let version: String?
    let bundleURL: URL
    let architectures: [String]
    let sizeBytes: Int64

    init(bundleURL: URL, bundleIdentifier: String?, version: String?, architectures: [String], sizeBytes: Int64) {
        self.id = bundleURL
        self.bundleURL = bundleURL
        self.name = bundleURL.deletingPathExtension().lastPathComponent
        self.bundleIdentifier = bundleIdentifier
        self.version = version
        self.architectures = architectures
        self.sizeBytes = sizeBytes
    }

    /// Vero se l'app non contiene una slice nativa arm64: su Apple Silicon gira solo
    /// tramite la traduzione Rosetta 2.
    var isIntelOnly: Bool {
        !architectures.contains("arm64") && !architectures.isEmpty
    }

    /// Vero se l'app contiene sia la slice arm64 sia quella x86_64: la parte Intel può
    /// essere rimossa per risparmiare spazio, tenendo solo il nativo Apple Silicon.
    var isUniversal: Bool {
        architectures.contains("arm64") && architectures.contains("x86_64")
    }

    /// App scaricate dal Mac App Store: verificano la propria firma Apple originale
    /// all'avvio, quindi ri-firmarle dopo averle modificate le rompe quasi sempre.
    var isMacAppStoreApp: Bool {
        FileManager.default.fileExists(atPath: bundleURL.appendingPathComponent("Contents/_MASReceipt/receipt").path)
    }
}
