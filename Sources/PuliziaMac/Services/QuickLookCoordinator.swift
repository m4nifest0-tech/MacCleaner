import AppKit
import Quartz

/// Mostra l'anteprima Quick Look nativa (lo stesso pannello attivato dalla barra
/// spaziatrice nel Finder) per un singolo file, su richiesta esplicita da un pulsante.
final class QuickLookCoordinator: NSObject, QLPreviewPanelDataSource {
    static let shared = QuickLookCoordinator()

    private override init() {}

    private var url: URL?

    func preview(_ url: URL) {
        self.url = url
        guard let panel = QLPreviewPanel.shared() else { return }
        panel.dataSource = self
        panel.reloadData()
        panel.makeKeyAndOrderFront(nil)
    }

    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        url == nil ? 0 : 1
    }

    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        url as NSURL?
    }
}
