import SwiftUI

/// Anteprima del report prima di scegliere dove salvarlo: mostra esattamente il PDF
/// che verrebbe scritto su disco, così l'utente può controllare il contenuto (o
/// annullare) prima del pannello di salvataggio.
struct ReportPreviewSheet: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    let tempURL: URL
    let onSaved: (URL) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(settings.t("report.preview_title"))
                    .font(.headline)
                Spacer()
                Button(settings.t("common.cancel")) {
                    cleanUpTempFile()
                    dismiss()
                }
                Button(settings.t("report.save_button")) {
                    if let destination = ReportExporter.save(tempURL: tempURL) {
                        cleanUpTempFile()
                        dismiss()
                        onSaved(destination)
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()

            Divider()

            PDFKitView(url: tempURL)
        }
        .frame(minWidth: 560, minHeight: 680)
    }

    private func cleanUpTempFile() {
        try? FileManager.default.removeItem(at: tempURL)
    }
}
