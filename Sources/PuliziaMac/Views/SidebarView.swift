import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var settings: AppSettings
    @Binding var selection: AppSection?

    var body: some View {
        List(AppSection.allCases, selection: $selection) { section in
            Label(settings.t(section.titleKey), systemImage: section.systemImage)
                .tag(section)
        }
        .navigationTitle("PuliziaMac")
        .listStyle(.sidebar)
    }
}
