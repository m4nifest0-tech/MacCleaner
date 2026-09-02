import SwiftUI
import AppKit

struct DuplicateFinderView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var stats: StatsStore
    @EnvironmentObject private var exclusions: ExclusionStore
    @State private var selectedFolders: [URL] = [FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads")]
    @State private var groups: [DuplicateGroup] = []
    @State private var isScanning = false
    @State private var hasScanned = false
    @State private var selection: Set<URL> = []
    @State private var showCleanConfirmation = false
    @State private var lastFailures: [TrashService.Failure] = []

    private var selectedSize: Int64 {
        groups.flatMap(\.files).filter { selection.contains($0.id) }.reduce(0) { $0 + $1.sizeBytes }
    }

    private var confirmTrashTitle: String {
        settings.language == .italian
            ? "Spostare \(selection.count) file (\(selectedSize.formattedFileSize)) nel Cestino?"
            : "Move \(selection.count) files (\(selectedSize.formattedFileSize)) to the Trash?"
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
        VStack(alignment: .leading, spacing: 12) {
            folderPicker
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
        .navigationTitle(settings.t(AppSection.duplicateFinder.titleKey))
        .confirmationDialog(
            confirmTrashTitle,
            isPresented: $showCleanConfirmation,
            titleVisibility: .visible
        ) {
            Button(settings.t("common.move_to_trash"), role: .destructive) { cleanSelected() }
            Button(settings.t("common.cancel"), role: .cancel) {}
        }
    }

    private var folderPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(settings.t("dup.folders_header"))
                .font(.headline)
            HStack {
                ForEach(selectedFolders, id: \.self) { folder in
                    Text(folder.lastPathComponent)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(.quaternary, in: Capsule())
                }
                Button {
                    addFolder()
                } label: {
                    Label(settings.t("dup.add_folder"), systemImage: "plus")
                }
                Spacer()
            }
        }
    }

    private var header: some View {
        HStack {
            Button {
                Task { await runScan() }
            } label: {
                Label(settings.t("dup.search_button"), systemImage: "doc.on.doc")
            }
            .disabled(isScanning || selectedFolders.isEmpty)

            if isScanning {
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
        if isScanning {
            VStack {
                Spacer()
                ProgressView(settings.t("dup.analyzing"))
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if !hasScanned {
            ContentUnavailableView(settings.t("dup.choose_folder"), systemImage: "doc.on.doc")
        } else if groups.isEmpty {
            ContentUnavailableView(settings.t("dup.no_duplicates"), systemImage: "checkmark.circle")
        } else {
            List {
                ForEach(groups) { group in
                    Section {
                        ForEach(group.files) { file in
                            fileRow(file)
                        }
                    } header: {
                        HStack {
                            Text(identicalCopiesText(group.files.count))
                            Spacer()
                            Text(reclaimableText(group.reclaimableBytes))
                        }
                    }
                }
            }
        }
    }

    private func identicalCopiesText(_ count: Int) -> String {
        settings.language == .italian ? "\(count) copie identiche" : "\(count) identical copies"
    }

    private func reclaimableText(_ bytes: Int64) -> String {
        settings.language == .italian ? "recuperabile: \(bytes.formattedFileSize)" : "reclaimable: \(bytes.formattedFileSize)"
    }

    private func fileRow(_ file: DuplicateFile) -> some View {
        HStack {
            Button {
                toggle(file)
            } label: {
                Image(systemName: selection.contains(file.id) ? "checkmark.square.fill" : "square")
            }
            .buttonStyle(.plain)

            Text(file.path.path)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()
            SizeBadge(bytes: file.sizeBytes)

            QuickLookButton(url: file.path)

            Button {
                NSWorkspace.shared.activateFileViewerSelecting([file.path])
            } label: {
                Image(systemName: "finder")
            }
            .buttonStyle(.borderless)
        }
        .contentShape(Rectangle())
        .onTapGesture { toggle(file) }
    }

    private func toggle(_ file: DuplicateFile) {
        if selection.contains(file.id) {
            selection.remove(file.id)
        } else {
            selection.insert(file.id)
        }
    }

    private func addFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url, !selectedFolders.contains(url) {
            selectedFolders.append(url)
        }
    }

    private func runScan() async {
        isScanning = true
        selection.removeAll()
        lastFailures = []
        groups = await DuplicateFinder.find(in: selectedFolders, excludedFolders: exclusions.excludedFolders)
        hasScanned = true
        isScanning = false
    }

    private func cleanSelected() {
        let selectedFiles = groups.flatMap(\.files).filter { selection.contains($0.id) }
        Task {
            lastFailures = TrashService.moveToTrash(selectedFiles.map(\.path))
            let failedPaths = Set(lastFailures.map(\.path))
            let freed = selectedFiles.filter { !failedPaths.contains($0.path) }.reduce(0) { $0 + $1.sizeBytes }
            stats.recordFreed(freed)
            await runScan()
        }
    }
}
