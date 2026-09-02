import SwiftUI

/// Pulsante "occhio" che apre l'anteprima Quick Look nativa per un file, accanto
/// agli altri pulsanti riga (checkbox, rivela nel Finder) nelle liste di file.
struct QuickLookButton: View {
    @EnvironmentObject private var settings: AppSettings

    let url: URL

    var body: some View {
        Button {
            QuickLookCoordinator.shared.preview(url)
        } label: {
            Image(systemName: "eye")
        }
        .buttonStyle(.borderless)
        .help(settings.t("common.preview"))
    }
}
