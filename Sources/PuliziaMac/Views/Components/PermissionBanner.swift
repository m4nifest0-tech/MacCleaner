import SwiftUI
import AppKit

/// Avviso mostrato quando la scansione ha incontrato cartelle non leggibili: di solito
/// significa che a PuliziaMac manca "Accesso completo al disco" in Impostazioni di Sistema.
struct PermissionBanner: View {
    @EnvironmentObject private var settings: AppSettings
    let missingCount: Int

    private var titleText: String {
        settings.language == .italian
            ? "Alcune cartelle non sono accessibili (\(missingCount))"
            : "Some folders aren't accessible (\(missingCount))"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lock.shield")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 4) {
                Text(titleText)
                    .fontWeight(.semibold)
                Text(settings.t("permission.body"))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Button(settings.t("common.open_system_settings")) {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.link)
            }
            Spacer()
        }
        .padding(10)
        .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
    }
}
