import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var settings: AppSettings
    @Binding var selection: AppSection?
    @State private var searchText = ""

    private var filteredSections: [AppSection] {
        guard !searchText.isEmpty else { return AppSection.allCases }
        return AppSection.allCases.filter { section in
            settings.t(section.titleKey).localizedCaseInsensitiveContains(searchText) || section.matches(query: searchText)
        }
    }

    var body: some View {
        // Lista nativa con evidenziazione di sistema: un tentativo precedente di
        // disegnare le righe a mano (per far coincidere lo sfondo della selezione con
        // il colore d'accento scelto) rompeva il layout del testo su macOS. Lo sfondo
        // della selezione resta quindi quello di sistema; il colore d'accento scelto
        // si vede comunque sulle icone.
        Group {
            if filteredSections.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                List(filteredSections, selection: $selection) { section in
                    Label {
                        Text(settings.t(section.titleKey))
                            .lineLimit(1)
                    } icon: {
                        Image(systemName: section.systemImage)
                            .foregroundStyle(settings.accentTheme.color)
                    }
                    .tag(section)
                }
                .listStyle(.sidebar)
            }
        }
        .navigationTitle("PuliziaMac")
        .navigationSplitViewColumnWidth(min: 190, ideal: 210, max: 260)
        .searchable(text: $searchText, placement: .sidebar, prompt: settings.t("sidebar.search_prompt"))
    }
}
