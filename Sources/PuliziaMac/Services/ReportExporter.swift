import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// Genera il PDF del riepilogo (Panoramica: spazio su disco, totale liberato,
/// informazioni di sistema, contatti) e lo salva dove sceglie l'utente. Il rendering
/// avviene prima in un file temporaneo, così l'anteprima può essere mostrata prima di
/// chiedere dove salvare.
enum ReportExporter {
    @MainActor
    static func renderTempPDF(disk: DiskOverview?, totalFreed: Int64, language: AppLanguage) -> URL? {
        let page = ReportPageView(disk: disk, totalFreed: totalFreed, language: language)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("PuliziaMac-Report-\(UUID().uuidString).pdf")
        return renderToPDF(page, pageSize: ReportPageView.pageSize, outputURL: tempURL) ? tempURL : nil
    }

    /// Mostra il pannello di salvataggio e copia il PDF già renderizzato (in anteprima)
    /// nella destinazione scelta. Ritorna la destinazione se il salvataggio riesce, nil
    /// se l'utente annulla o la copia fallisce.
    @MainActor
    static func save(tempURL: URL) -> URL? {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = "PuliziaMac-Report.pdf"
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK, let destination = panel.url else { return nil }

        do {
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: tempURL, to: destination)
            return destination
        } catch {
            return nil
        }
    }

    @MainActor
    private static func renderToPDF<Content: View>(_ content: Content, pageSize: CGSize, outputURL: URL) -> Bool {
        let renderer = ImageRenderer(content: content)
        renderer.proposedSize = ProposedViewSize(pageSize)

        var mediaBox = CGRect(origin: .zero, size: pageSize)
        guard let context = CGContext(outputURL as CFURL, mediaBox: &mediaBox, nil) else { return false }

        var succeeded = false
        renderer.render { _, renderInContext in
            context.beginPDFPage(nil)
            renderInContext(context)
            context.endPDFPage()
            context.closePDF()
            succeeded = true
        }
        return succeeded
    }
}
