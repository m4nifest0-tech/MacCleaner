import Foundation

/// Contatore persistente dello spazio liberato da PuliziaMac nel tempo, aggiornato dai
/// vari moduli dopo ogni pulizia riuscita. Mostrato nella Dashboard.
final class StatsStore: ObservableObject {
    @Published private(set) var totalBytesFreed: Int64 {
        didSet { defaults.set(totalBytesFreed, forKey: Keys.totalFreed) }
    }

    private let defaults: UserDefaults

    private enum Keys {
        static let totalFreed = "statsTotalBytesFreed"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        totalBytesFreed = Int64(defaults.integer(forKey: Keys.totalFreed))
    }

    func recordFreed(_ bytes: Int64) {
        guard bytes > 0 else { return }
        totalBytesFreed += bytes
    }
}
