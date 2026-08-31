import SwiftUI

struct LoginItemsView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var items: [LoginItem] = []
    @State private var isLoading = false
    @State private var disablingID: URL?
    @State private var itemPendingConfirmation: LoginItem?
    @State private var showDisableConfirmation = false
    @State private var lastErrorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            explanation

            if let lastErrorMessage {
                Text(lastErrorMessage)
                    .font(.callout)
                    .foregroundStyle(.red)
            }

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .navigationTitle(settings.t(AppSection.loginItems.titleKey))
        .task {
            if items.isEmpty { loadItems() }
        }
        .confirmationDialog(
            disableConfirmTitle,
            isPresented: $showDisableConfirmation,
            titleVisibility: .visible
        ) {
            Button(settings.t("loginitems.disable_button"), role: .destructive) {
                if let itemPendingConfirmation { disable(itemPendingConfirmation) }
            }
            Button(settings.t("common.cancel"), role: .cancel) { itemPendingConfirmation = nil }
        }
    }

    private var disableConfirmTitle: String {
        let name = itemPendingConfirmation.map(LoginItemsService.displayName(for:)) ?? ""
        return settings.language == .italian
            ? "Disattivare \"\(name)\" all'avvio?"
            : "Disable \"\(name)\" at login?"
    }

    private var header: some View {
        HStack {
            Button {
                loadItems()
            } label: {
                Label(settings.t("loginitems.refresh_button"), systemImage: "arrow.clockwise")
            }
            .disabled(isLoading)

            if isLoading {
                ProgressView().controlSize(.small)
            }

            Spacer()
        }
    }

    private var explanation: some View {
        Text(settings.t("loginitems.explanation"))
            .font(.callout)
            .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var content: some View {
        if items.isEmpty {
            ContentUnavailableView(settings.t("loginitems.empty"), systemImage: "person.badge.clock")
        } else {
            List(items) { item in
                itemRow(item)
            }
        }
    }

    private func itemRow(_ item: LoginItem) -> some View {
        HStack {
            if let appURL = LoginItemsService.appBundleURL(for: item) {
                AppIconView(path: appURL, size: 24)
            } else {
                Image(systemName: "gearshape.2")
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading) {
                HStack(spacing: 6) {
                    Text(LoginItemsService.displayName(for: item))
                    if item.scope == .system {
                        badge(settings.t("loginitems.system_badge"))
                    }
                }
                Text(item.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            if disablingID == item.id {
                ProgressView().controlSize(.small)
            } else {
                Button(settings.t("loginitems.disable_button")) {
                    itemPendingConfirmation = item
                    showDisableConfirmation = true
                }
                .font(.caption)
            }
        }
    }

    private func badge(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.orange.opacity(0.2), in: Capsule())
            .foregroundStyle(.orange)
    }

    private func loadItems() {
        isLoading = true
        lastErrorMessage = nil
        items = LoginItemsService.scan()
        isLoading = false
    }

    private func disable(_ item: LoginItem) {
        disablingID = item.id
        Task {
            let result = await LoginItemsService.disable(item)
            disablingID = nil
            itemPendingConfirmation = nil
            if !result.success {
                lastErrorMessage = result.errorMessage
            } else {
                lastErrorMessage = nil
            }
            loadItems()
        }
    }
}
