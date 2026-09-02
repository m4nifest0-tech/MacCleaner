import SwiftUI
import AppKit

private enum ExplorerViewMode: CaseIterable, Identifiable {
    case list
    case graphic

    var id: Self { self }

    var titleKey: String {
        switch self {
        case .list: return "diskexplorer.view_list"
        case .graphic: return "diskexplorer.view_graphic"
        }
    }

    var systemImage: String {
        switch self {
        case .list: return "list.bullet"
        case .graphic: return "square.grid.2x2"
        }
    }
}

struct DiskExplorerView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var stats: StatsStore
    @EnvironmentObject private var exclusions: ExclusionStore

    @State private var currentDirectory = FileManager.default.homeDirectoryForCurrentUser
    @State private var entries: [DiskExplorerEntry] = []
    @State private var isLoading = false
    @State private var selection: Set<URL> = []
    @State private var showCleanConfirmation = false
    @State private var lastFailures: [TrashService.Failure] = []
    @State private var viewMode: ExplorerViewMode = .list

    private var selectedSize: Int64 {
        entries.filter { selection.contains($0.id) }.reduce(0) { $0 + $1.sizeBytes }
    }

    private var confirmTrashTitle: String {
        settings.language == .italian
            ? "Spostare \(selection.count) elementi (\(selectedSize.formattedFileSize)) nel Cestino?"
            : "Move \(selection.count) items (\(selectedSize.formattedFileSize)) to the Trash?"
    }

    private var failuresText: String {
        settings.language == .italian
            ? "Non è stato possibile spostare \(lastFailures.count) elementi nel Cestino."
            : "Couldn't move \(lastFailures.count) items to the Trash."
    }

    private var selectionSummary: String {
        settings.language == .italian
            ? "\(selection.count) selezionati · \(selectedSize.formattedFileSize)"
            : "\(selection.count) selected · \(selectedSize.formattedFileSize)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            shortcutsRow
            breadcrumb
            header

            if !lastFailures.isEmpty {
                Text(failuresText)
                    .font(.callout)
                    .foregroundStyle(.red)
            }

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .navigationTitle(settings.t(AppSection.diskExplorer.titleKey))
        .task(id: currentDirectory) {
            await load()
        }
        .confirmationDialog(
            confirmTrashTitle,
            isPresented: $showCleanConfirmation,
            titleVisibility: .visible
        ) {
            Button(settings.t("common.move_to_trash"), role: .destructive) { cleanSelected() }
            Button(settings.t("common.cancel"), role: .cancel) {}
        }
    }

    private var shortcutsRow: some View {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let shortcuts: [(String, URL)] = [
            (settings.t("diskexplorer.shortcut_home"), home),
            (settings.t("diskexplorer.shortcut_applications"), URL(fileURLWithPath: "/Applications")),
            (settings.t("diskexplorer.shortcut_documents"), home.appendingPathComponent("Documents")),
            (settings.t("diskexplorer.shortcut_downloads"), home.appendingPathComponent("Downloads")),
            (settings.t("diskexplorer.shortcut_desktop"), home.appendingPathComponent("Desktop"))
        ]
        return HStack {
            ForEach(shortcuts, id: \.1) { label, url in
                Button(label) { navigate(to: url) }
                    .buttonStyle(.link)
            }
            Spacer()
        }
        .font(.callout)
    }

    private var breadcrumb: some View {
        let components = breadcrumbComponents
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(Array(components.enumerated()), id: \.offset) { index, component in
                    Button(component.name) { navigate(to: component.url) }
                        .buttonStyle(.plain)
                        .foregroundStyle(index == components.count - 1 ? .primary : .secondary)
                    if index < components.count - 1 {
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var breadcrumbComponents: [(name: String, url: URL)] {
        var result: [(String, URL)] = []
        var url = currentDirectory
        while true {
            let name = url.pathComponents.count <= 1 ? "/" : url.lastPathComponent
            result.append((name, url))
            if url.pathComponents.count <= 1 { break }
            url.deleteLastPathComponent()
        }
        return result.reversed()
    }

    private var header: some View {
        HStack {
            Picker("", selection: $viewMode) {
                ForEach(ExplorerViewMode.allCases) { mode in
                    Label(settings.t(mode.titleKey), systemImage: mode.systemImage).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: 200)

            if isLoading {
                ProgressView().controlSize(.small)
            }

            Spacer()

            if !selection.isEmpty {
                Text(selectionSummary)
                    .foregroundStyle(.secondary)
            }

            Button(role: .destructive) {
                showCleanConfirmation = true
            } label: {
                Label(settings.t("cache.clean_selected"), systemImage: "trash")
            }
            .disabled(selection.isEmpty)
        }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            VStack {
                Spacer()
                ProgressView(settings.t("diskexplorer.loading"))
                Spacer()
            }
        } else if entries.isEmpty {
            ContentUnavailableView(settings.t("diskexplorer.empty"), systemImage: "folder")
        } else if viewMode == .graphic {
            SpaceBreakdownView(
                entries: entries,
                isSelected: { selection.contains($0.id) },
                isExcluded: { exclusions.isExcluded($0.path) },
                onToggleSelection: toggle,
                onNavigate: { navigate(to: $0.path) }
            )
        } else {
            List(entries) { entry in
                entryRow(entry)
            }
        }
    }

    private func handleTap(_ entry: DiskExplorerEntry) {
        if entry.isNavigable {
            navigate(to: entry.path)
        } else {
            toggle(entry)
        }
    }

    private func entryRow(_ entry: DiskExplorerEntry) -> some View {
        let isExcluded = exclusions.isExcluded(entry.path)
        return HStack {
            Button {
                toggle(entry)
            } label: {
                Image(systemName: selection.contains(entry.id) ? "checkmark.square.fill" : "square")
            }
            .buttonStyle(.plain)
            .disabled(isExcluded)
            .opacity(isExcluded ? 0.3 : 1)
            .help(isExcluded ? settings.t("diskexplorer.excluded_tooltip") : "")

            AppIconView(path: entry.path, size: 20)

            Text(entry.name)
                .lineLimit(1)

            if isExcluded {
                Image(systemName: "lock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
            SizeBadge(bytes: entry.sizeBytes)

            if entry.isNavigable {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                QuickLookButton(url: entry.path)
            }

            Button {
                NSWorkspace.shared.activateFileViewerSelecting([entry.path])
            } label: {
                Image(systemName: "finder")
            }
            .buttonStyle(.borderless)
            .help(settings.t("common.reveal_finder"))
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard entry.isNavigable || !isExcluded else { return }
            handleTap(entry)
        }
    }

    private func toggle(_ entry: DiskExplorerEntry) {
        guard !exclusions.isExcluded(entry.path) else { return }
        if selection.contains(entry.id) {
            selection.remove(entry.id)
        } else {
            selection.insert(entry.id)
        }
    }

    private func navigate(to url: URL) {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        selection.removeAll()
        lastFailures = []
        currentDirectory = url
    }

    private func load() async {
        isLoading = true
        entries = await DiskExplorerService.listEntries(in: currentDirectory)
        isLoading = false
    }

    private func cleanSelected() {
        let selectedEntries = entries.filter { selection.contains($0.id) }
        Task {
            lastFailures = TrashService.moveToTrash(selectedEntries.map(\.path))
            let failedPaths = Set(lastFailures.map(\.path))
            let freed = selectedEntries.filter { !failedPaths.contains($0.path) }.reduce(0) { $0 + $1.sizeBytes }
            stats.recordFreed(freed)
            selection.removeAll()
            await load()
        }
    }
}
