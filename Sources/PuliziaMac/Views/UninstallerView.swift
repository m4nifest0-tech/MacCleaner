import SwiftUI

struct UninstallerView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var apps: [AppBundleInfo] = []
    @State private var isLoadingApps = false
    @State private var searchText = ""
    @State private var selectedApp: AppBundleInfo?
    @State private var candidate: UninstallCandidate?
    @State private var isLoadingLeftovers = false
    @State private var selectedLeftovers: Set<URL> = []
    @State private var showUninstallConfirmation = false
    @State private var lastFailures: [TrashService.Failure] = []

    private var filteredApps: [AppBundleInfo] {
        guard !searchText.isEmpty else { return apps }
        return apps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        HSplitView {
            appListPane
            detailPane
        }
        .navigationTitle(settings.t(AppSection.uninstaller.titleKey))
        .task {
            if apps.isEmpty { await loadApps() }
        }
    }

    private var appListPane: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField(settings.t("uninstall.search_placeholder"), text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding([.horizontal, .top])

            if isLoadingApps {
                ProgressView().padding()
            }

            List(filteredApps, selection: $selectedApp) { app in
                HStack {
                    AppIconView(path: app.bundleURL, size: 24)
                    VStack(alignment: .leading) {
                        Text(app.name)
                        Text(app.sizeBytes.formattedFileSize)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .tag(app)
            }
        }
        .frame(minWidth: 240, idealWidth: 280)
        .onChange(of: selectedApp) { _, newValue in
            guard let newValue else { return }
            Task { await loadLeftovers(for: newValue) }
        }
    }

    @ViewBuilder
    private var detailPane: some View {
        Group {
            if let candidate {
                detailContent(candidate)
            } else {
                ContentUnavailableView(settings.t("uninstall.select_app"), systemImage: "minus.circle")
            }
        }
        .frame(minWidth: 380, maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var failuresText: String {
        settings.language == .italian
            ? "Non è stato possibile spostare \(lastFailures.count) elementi nel Cestino."
            : "Couldn't move \(lastFailures.count) items to the Trash."
    }

    private func detailContent(_ candidate: UninstallCandidate) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                AppIconView(path: candidate.app.bundleURL, size: 40)
                VStack(alignment: .leading) {
                    Text(candidate.app.name).font(.title2).bold()
                    Text(candidate.app.bundleIdentifier ?? "—")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                SizeBadge(bytes: candidate.app.sizeBytes)
            }

            if !lastFailures.isEmpty {
                Text(failuresText)
                    .font(.callout)
                    .foregroundStyle(.red)
            }

            Text(settings.t("uninstall.leftovers_header"))
                .font(.headline)

            if isLoadingLeftovers {
                ProgressView(settings.t("uninstall.searching_leftovers"))
            } else if candidate.leftovers.isEmpty {
                Text(settings.t("uninstall.no_leftovers"))
                    .foregroundStyle(.secondary)
            } else {
                List(candidate.leftovers) { leftover in
                    HStack {
                        Button {
                            toggle(leftover)
                        } label: {
                            Image(systemName: selectedLeftovers.contains(leftover.id) ? "checkmark.square.fill" : "square")
                        }
                        .buttonStyle(.plain)

                        Text(leftover.path.path)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                        SizeBadge(bytes: leftover.sizeBytes)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { toggle(leftover) }
                }
            }

            Spacer()

            Button(role: .destructive) {
                showUninstallConfirmation = true
            } label: {
                Label(settings.t("uninstall.button"), systemImage: "trash")
            }
            .disabled(isLoadingLeftovers)
        }
        .padding()
        .confirmationDialog(
            uninstallConfirmTitle(candidate),
            isPresented: $showUninstallConfirmation,
            titleVisibility: .visible
        ) {
            Button(settings.t("uninstall.confirm_button"), role: .destructive) { uninstall(candidate) }
            Button(settings.t("common.cancel"), role: .cancel) {}
        }
    }

    private func uninstallConfirmTitle(_ candidate: UninstallCandidate) -> String {
        settings.language == .italian
            ? "Spostare \"\(candidate.app.name)\" e \(selectedLeftovers.count) file residui nel Cestino?"
            : "Move \"\(candidate.app.name)\" and \(selectedLeftovers.count) leftover files to the Trash?"
    }

    private func toggle(_ leftover: LeftoverFile) {
        if selectedLeftovers.contains(leftover.id) {
            selectedLeftovers.remove(leftover.id)
        } else {
            selectedLeftovers.insert(leftover.id)
        }
    }

    private func loadApps() async {
        isLoadingApps = true
        apps = await ArchScanner.scan()
        isLoadingApps = false
    }

    private func loadLeftovers(for app: AppBundleInfo) async {
        isLoadingLeftovers = true
        lastFailures = []
        let leftovers = await UninstallerService.findLeftovers(for: app)
        candidate = UninstallCandidate(app: app, leftovers: leftovers)
        selectedLeftovers = Set(leftovers.map(\.id)) // preselezionati: sono già stati trovati per corrispondenza esatta
        isLoadingLeftovers = false
    }

    private func uninstall(_ candidate: UninstallCandidate) {
        let leftoverPaths = candidate.leftovers.filter { selectedLeftovers.contains($0.id) }.map(\.path)
        Task {
            lastFailures = UninstallerService.uninstall(candidate, removingLeftovers: leftoverPaths)
            self.candidate = nil
            selectedApp = nil
            await loadApps()
        }
    }
}
