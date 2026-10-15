import SwiftUI

struct MemoryView: View {
    @EnvironmentObject private var settings: AppSettings

    @State private var memory: MemoryInfo?
    @State private var isLoading = false
    @State private var isPurging = false
    @State private var purgeMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                explanation

                if let memory {
                    overviewCard(memory)
                } else if isLoading {
                    ProgressView(settings.t("memory.loading"))
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                } else {
                    ContentUnavailableView(settings.t("memory.unavailable"), systemImage: "memorychip")
                }
            }
            .padding()
        }
        .navigationTitle(settings.t(AppSection.memoryCleaner.titleKey))
        .task {
            if memory == nil { await load() }
        }
    }

    private var header: some View {
        HStack {
            Button {
                Task { await load() }
            } label: {
                Label(settings.t("memory.refresh"), systemImage: "arrow.clockwise")
            }
            .disabled(isLoading)

            if isLoading {
                ProgressView().controlSize(.small)
            }
            Spacer()
        }
    }

    private var explanation: some View {
        Text(settings.t("memory.explanation"))
            .font(.callout)
            .foregroundStyle(.secondary)
    }

    private func overviewCard(_ memory: MemoryInfo) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 24) {
                gauge(memory)

                VStack(alignment: .leading, spacing: 8) {
                    breakdownRow(color: settings.accentTheme.color, label: settings.t("memory.wired"), bytes: memory.wiredBytes)
                    breakdownRow(color: settings.accentTheme.color.opacity(0.7), label: settings.t("memory.active"), bytes: memory.activeBytes)
                    breakdownRow(color: settings.accentTheme.color.opacity(0.4), label: settings.t("memory.compressed"), bytes: memory.compressedBytes)
                    breakdownRow(color: .gray.opacity(0.5), label: settings.t("memory.inactive"), bytes: memory.inactiveBytes)
                    breakdownRow(color: .gray.opacity(0.25), label: settings.t("memory.free"), bytes: memory.freeBytes)
                }
                .font(.callout)

                Spacer()
            }

            Divider()

            HStack {
                Button {
                    purgeMemory()
                } label: {
                    Label(settings.t("memory.purge_button"), systemImage: "memorychip")
                }
                .disabled(isPurging)

                if isPurging {
                    ProgressView().controlSize(.small)
                }

                Spacer()

                if let purgeMessage {
                    Text(purgeMessage)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
    }

    private func breakdownRow(color: Color, label: String, bytes: Int64) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text("\(label): \(bytes.formattedMemorySize)")
        }
    }

    private func gauge(_ memory: MemoryInfo) -> some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.15), lineWidth: 14)
            Circle()
                .trim(from: 0, to: max(memory.usedFraction, 0.015))
                .stroke(settings.accentTheme.color, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 1) {
                Text("\(Int((memory.usedFraction * 100).rounded()))%")
                    .font(.title2.bold())
                    .monospacedDigit()
                Text(settings.t("memory.used"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 108, height: 108)
        .animation(.easeInOut(duration: 0.4), value: memory.usedFraction)
    }

    private func load() async {
        isLoading = true
        memory = await MemoryInfoProvider.current()
        isLoading = false
    }

    private func purgeMemory() {
        isPurging = true
        purgeMessage = nil
        Task {
            let result = await MemoryService.purgeInactiveMemory()
            purgeMessage = result.success ? settings.t("memory.purge_success") : result.errorMessage
            await load()
            isPurging = false
        }
    }
}
