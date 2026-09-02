import SwiftUI
import AppKit

/// Contenuto della pagina PDF esportata: layout fisso in punti (formato Letter),
/// colori espliciti bianco/nero perché un documento stampabile non deve dipendere dal
/// tema chiaro/scuro dell'app in quel momento.
struct ReportPageView: View {
    let disk: DiskOverview?
    let totalFreed: Int64
    let language: AppLanguage

    static let pageSize = CGSize(width: 612, height: 792) // US Letter a 72dpi

    private let system = SystemInfoProvider.current()
    private let contactName = "m4nifest0"
    private let contactGitHub = "github.com/m4nifest0-tech"

    private func t(_ key: String) -> String {
        Localization.string(key, language: language)
    }

    private var generatedDateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: language == .italian ? "it_IT" : "en_US")
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            header

            Text(t("report.title"))
                .font(.system(size: 22, weight: .bold))

            if let disk {
                statBlock(title: t("dashboard.disk_usage")) {
                    statRow(t("dashboard.used"), disk.usedBytes.formattedFileSize)
                    statRow(t("dashboard.free"), disk.freeBytes.formattedFileSize)
                    statRow(t("report.total_capacity"), disk.totalBytes.formattedFileSize)
                }
            }

            statBlock(title: t("dashboard.total_freed")) {
                Text(totalFreed.formattedFileSize)
                    .font(.system(size: 26, weight: .bold))
            }

            statBlock(title: t("report.system_info")) {
                statRow(t("report.computer_name"), system.computerName)
                statRow(t("report.mac_model"), system.modelIdentifier)
                statRow(t("report.macos_version"), system.macOSVersion)
            }

            Spacer()

            Divider()

            HStack {
                Text(t("report.footer"))
                    .font(.caption)
                    .foregroundStyle(Color.black.opacity(0.5))
                Spacer()
                Text("\(t("report.contact")): \(contactName) · \(contactGitHub)")
                    .font(.caption)
                    .foregroundStyle(Color.black.opacity(0.5))
            }
        }
        .padding(40)
        .frame(width: Self.pageSize.width, height: Self.pageSize.height, alignment: .topLeading)
        .background(Color.white)
        .foregroundStyle(Color.black)
    }

    private var header: some View {
        HStack(alignment: .top) {
            if let logoURL = AppResources.logoURL, let logo = NSImage(contentsOf: logoURL) {
                Image(nsImage: logo)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("PuliziaMac")
                    .font(.system(size: 16, weight: .semibold))
                Text("\(t("report.generated_on")) \(generatedDateText)")
                    .font(.caption)
                    .foregroundStyle(Color.black.opacity(0.6))
            }
        }
    }

    private func statBlock<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.7))
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value).fontWeight(.medium)
        }
        .font(.system(size: 13))
    }
}

/// Risorse incluse nel bundle dell'app (copiate da `Scripts/build_app.sh`, non
/// processate da Swift Package Manager: stesso meccanismo già usato per l'icona).
enum AppResources {
    static var logoURL: URL? {
        Bundle.main.url(forResource: "Logo", withExtension: "jpeg")
    }
}
