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

            MenuRow(title: settings.t("menubar.open_smart_clean"), systemImage: "wand.and.sparkles") {
                open(.smartClean)
            }

            MenuRow(title: settings.t("menubar.open_app"), systemImage: "macwindow") {
                open(nav.selection ?? .dashboard)
            }

            Divider()

            MenuRow(title: settings.t("menubar.quit"), systemImage: "power") {
                NSApp.terminate(nil)
            }
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

/// Riga stile menù con evidenziazione al passaggio del mouse: nel pannello del
/// MenuBarExtra (`.menuBarExtraStyle(.window)`) non è un vero NSMenu, quindi
/// l'hover va gestito a mano — altrimenti passare il mouse sulle voci non dà alcun
/// riscontro visivo.
private struct MenuRow: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    isHovering ? Color.primary.opacity(0.08) : Color.clear,
                    in: RoundedRectangle(cornerRadius: 6)
                )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
    }
}
