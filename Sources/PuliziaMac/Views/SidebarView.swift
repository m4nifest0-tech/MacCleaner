import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var settings: AppSettings
    @Binding var selection: AppSection?

    var body: some View {
        // Lista nativa con evidenziazione di sistema: un tentativo precedente di
        // disegnare le righe a mano (per far coincidere lo sfondo della selezione con
        // il colore d'accento scelto) rompeva il layout del testo su macOS. Lo sfondo
        // della selezione resta quindi quello di sistema; il colore d'accento scelto
        // si vede comunque sulle icone.
        List(AppSection.allCases, selection: $selection) { section in
            Label {
                Text(settings.t(section.titleKey))
                    .lineLimit(1)
            } icon: {
                Image(systemName: section.systemImage)
                    .foregroundStyle(settings.accentTheme.color)
            }
            .tag(section)
        }
        .navigationTitle("PuliziaMac")
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 190, ideal: 210, max: 260)
    }
}
