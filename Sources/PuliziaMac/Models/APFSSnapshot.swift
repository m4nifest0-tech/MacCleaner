import Foundation

/// Uno snapshot locale APFS creato automaticamente da Time Machine (visibile con
/// `tmutil listlocalsnapshots /`), non un vero backup: occupa spazio solo per le
/// differenze rispetto al disco attuale e macOS lo elimina da solo quando serve
/// spazio, ma può essere rimosso subito a mano per liberarlo immediatamente.
struct APFSSnapshot: Identifiable, Hashable {
    /// Componente data usata anche da `tmutil deletelocalsnapshots <date>`.
    let id: String
    let fullName: String
    let date: Date?
}
