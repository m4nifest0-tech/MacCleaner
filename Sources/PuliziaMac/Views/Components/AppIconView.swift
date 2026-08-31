import SwiftUI
import AppKit

/// Icona reale di un file/app presa da macOS (stessa icona che si vede nel Finder).
struct AppIconView: View {
    let path: URL
    var size: CGFloat = 28

    var body: some View {
        Image(nsImage: NSWorkspace.shared.icon(forFile: path.path))
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
    }
}
