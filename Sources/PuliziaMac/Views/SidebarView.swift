import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var settings: AppSettings
    @Binding var selection: AppSection?

    var body: some View {
        List {
            ForEach(AppSection.allCases) { section in
                row(for: section)
            }
        }
        .navigationTitle("PuliziaMac")
        .listStyle(.sidebar)
    }

    /// Riga disegnata a mano (invece di affidarsi all'evidenziazione nativa di
    /// `List(selection:)`) perché macOS applica alla selezione della sidebar il colore
    /// accento *di sistema*, ignorando `.tint()`: per riflettere davvero il colore
    /// scelto nelle Impostazioni dobbiamo colorare noi lo sfondo della riga selezionata.
    private func row(for section: AppSection) -> some View {
        let isSelected = selection == section
        return Label(settings.t(section.titleKey), systemImage: section.systemImage)
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.vertical, 4)
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? settings.accentTheme.color : Color.clear, in: RoundedRectangle(cornerRadius: 6))
            .contentShape(Rectangle())
            .onTapGesture { selection = section }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8))
    }
}
