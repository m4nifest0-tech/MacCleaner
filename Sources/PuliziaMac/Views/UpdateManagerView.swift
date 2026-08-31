import SwiftUI

struct UpdateManagerView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var brewAvailability: ToolAvailability = .notInstalled
    @State private var masAvailability: ToolAvailability = .notInstalled
    @State private var items: [UpdateItem] = []
    @State private var isScanning = false
    @State private var upgradingIDs: Set<String> = []
    @State private var isInstallingMas = false
    @State private var showInstallMasConfirmation = false
    @State private var masInstallError: String?
    /// Frazione (0...1) di controlli completati (Homebrew, Mac App Store): riflette
    /// passi reali già eseguiti, non un'animazione finta.
    @State private var scanProgress: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            // Il pulsante in alto resta alla sua dimensione naturale; il contenuto
            // sotto riempie lo spazio restante, così un messaggio corto (es. "Tutto
            // aggiornato") si centra in quello spazio invece di restare appiccicato
            // subito sotto il pulsante.
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .navigationTitle(settings.t(AppSection.updateManager.titleKey))
        .task {
            await refresh()
        }
        .confirmationDialog(
            settings.t("updates.install_mas_confirm_title"),
            isPresented: $showInstallMasConfirmation,
            titleVisibility: .visible
        ) {
            Button(settings.t("updates.install_button")) { Task { await installMas() } }
            Button(settings.t("common.cancel"), role: .cancel) {}
        } message: {
            Text(settings.t("updates.install_mas_confirm_message"))
        }
    }

    private var header: some View {
        HStack {
            Button {
                Task { await refresh() }
            } label: {
                Label(settings.t("updates.check_button"), systemImage: "arrow.triangle.2.circlepath")
            }
            .disabled(isScanning)

            if isScanning {
                ProgressView(value: scanProgress)
                    .frame(width: 90)
                Text("\(Int(scanProgress * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Spacer()
        }
    }

    private var bothToolsMissing: Bool {
        if case .notInstalled = brewAvailability, case .notInstalled = masAvailability {
            return true
        }
        return false
    }

    @ViewBuilder
    private var content: some View {
        if bothToolsMissing {
            ContentUnavailableView(
                settings.t("updates.none_tools_title"),
                systemImage: "shippingbox",
                description: Text(settings.t("updates.none_tools_desc"))
            )
        } else {
            if isScanning && items.isEmpty {
                VStack {
                    Spacer()
                    ProgressView(settings.t("updates.checking"))
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if items.isEmpty {
                ContentUnavailableView(settings.t("updates.none_available"), systemImage: "checkmark.circle")
            } else {
                List(items) { item in
                    itemRow(item)
                }
            }

            missingMasBanner
        }
    }

    @ViewBuilder
    private var missingMasBanner: some View {
        if case .notInstalled = masAvailability {
            HStack {
                Text(settings.t("updates.mas_missing"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if case .available = brewAvailability {
                    if isInstallingMas {
                        ProgressView().controlSize(.small)
                    } else {
                        Button(settings.t("updates.install_mas_button")) { showInstallMasConfirmation = true }
                            .font(.caption)
                    }
                }
            }
            if let masInstallError {
                Text(masInstallError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private func itemRow(_ item: UpdateItem) -> some View {
        HStack {
            if let appURL = installedAppURL(for: item) {
                AppIconView(path: appURL, size: 24)
            } else {
                Image(systemName: item.source == .homebrew ? "shippingbox" : "bag")
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading) {
                Text(item.name)
                Text("\(item.source.title) · \(item.installedVersion ?? "?") → \(item.availableVersion ?? "?")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if upgradingIDs.contains(item.id) {
                ProgressView().controlSize(.small)
            } else {
                Button(settings.t("updates.update_button")) {
                    Task { await upgrade(item) }
                }
            }
        }
    }

    /// Cerca l'app installata corrispondente a una voce di aggiornamento, per mostrarne
    /// l'icona reale. Confronto esatto sul nome per evitare falsi positivi.
    private func installedAppURL(for item: UpdateItem) -> URL? {
        let fm = FileManager.default
        let candidateDirs = [
            URL(fileURLWithPath: "/Applications"),
            fm.homeDirectoryForCurrentUser.appendingPathComponent("Applications")
        ]
        for dir in candidateDirs {
            let candidate = dir.appendingPathComponent("\(item.name).app")
            if fm.fileExists(atPath: candidate.path) {
                return candidate
            }
        }
        return nil
    }

    private func installMas() async {
        guard case .available(let brewPath) = brewAvailability else { return }
        isInstallingMas = true
        masInstallError = nil
        let success = await UpdateManager.installHomebrewPackage(brewPath: brewPath, name: "mas")
        isInstallingMas = false
        if !success {
            masInstallError = settings.t("updates.install_error")
        }
        await refresh()
    }

    private func refresh() async {
        isScanning = true
        scanProgress = 0
        brewAvailability = UpdateManager.locateBrew()
        masAvailability = UpdateManager.locateMas()

        var steps: [() async -> [UpdateItem]] = []
        if case .available(let path) = brewAvailability {
            steps.append { await UpdateManager.homebrewOutdated(brewPath: path) }
        }
        if case .available(let path) = masAvailability {
            steps.append { await UpdateManager.masOutdated(masPath: path) }
        }

        var collected: [UpdateItem] = []
        if steps.isEmpty {
            scanProgress = 1
        } else {
            for (index, step) in steps.enumerated() {
                collected += await step()
                scanProgress = Double(index + 1) / Double(steps.count)
            }
        }
        items = collected
        isScanning = false
    }

    private func upgrade(_ item: UpdateItem) async {
        upgradingIDs.insert(item.id)
        switch item.source {
        case .homebrew:
            if case .available(let path) = brewAvailability {
                _ = await UpdateManager.upgradeHomebrewPackage(brewPath: path, name: item.name)
            }
        case .masAppStore:
            if case .available(let path) = masAvailability {
                let id = item.id.replacingOccurrences(of: "mas:", with: "")
                _ = await UpdateManager.upgradeMasApp(masPath: path, id: id)
            }
        }
        upgradingIDs.remove(item.id)
        await refresh()
    }
}
