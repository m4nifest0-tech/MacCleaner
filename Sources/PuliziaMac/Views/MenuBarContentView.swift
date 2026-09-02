import SwiftUI
import AppKit

/// Contenuto del pannello che compare cliccando l'icona di PuliziaMac nella barra dei
/// menù: un colpo d'occhio su spazio libero/liberato e un accesso rapido alla finestra
/// principale, senza dover tenere l'app in primo piano.
struct MenuBarContentView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var stats: StatsStore
    @EnvironmentObject private var nav: NavigationState
    @Environment(\.openWindow) private var openWindow

    @State private var disk: DiskOverview?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let disk {
                HStack {
                    Label(settings.t("dashboard.free"), systemImage: "internaldrive")
                    Spacer()
                    Text(disk.freeBytes.formattedFileSize).monospacedDigit()
                }
                HStack {
                    Label(settings.t("dashboard.used"), systemImage: "chart.pie")
                    Spacer()
                    Text(disk.usedBytes.formattedFileSize).monospacedDigit()
                }
            }

            HStack {
                Label(settings.t("dashboard.total_freed"), systemImage: "sparkles")
                Spacer()
                Text(stats.totalBytesFreed.formattedFileSize).monospacedDigit()
            }

            Divider()

            Button {
                open(.smartClean)
            } label: {
                Label(settings.t("menubar.open_smart_clean"), systemImage: "wand.and.sparkles")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            Button {
                open(nav.selection ?? .dashboard)
            } label: {
                Label(settings.t("menubar.open_app"), systemImage: "macwindow")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            Divider()

            Button {
                NSApp.terminate(nil)
            } label: {
                Label(settings.t("menubar.quit"), systemImage: "power")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .frame(width: 260)
        .onAppear { disk = DiskOverview.current() }
    }

    private func open(_ section: AppSection) {
        nav.selection = section
        openWindow(id: "main")
        NSApp.activate(ignoringOtherApps: true)
    }
}
