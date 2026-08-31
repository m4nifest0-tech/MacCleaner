import Foundation

struct ThinResult {
    let appName: String
    let sizeBefore: Int64
    let sizeAfter: Int64
    let success: Bool
    let errorMessage: String?
    /// Vero se il fallimento è dovuto al permesso "Gestione app" negato a PuliziaMac:
    /// macOS lo applica anche ai processi con privilegi di amministratore, quindi va
    /// concesso esplicitamente in Impostazioni di Sistema.
    var requiresAppManagementPermission: Bool = false

    var freedBytes: Int64 { max(sizeBefore - sizeAfter, 0) }
}
