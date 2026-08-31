import Foundation

enum UpdateSource: String {
    case homebrew
    case masAppStore

    var title: String {
        switch self {
        case .homebrew: return "Homebrew"
        case .masAppStore: return "Mac App Store"
        }
    }
}

struct UpdateItem: Identifiable, Hashable {
    let id: String
    let source: UpdateSource
    let name: String
    let installedVersion: String?
    let availableVersion: String?
}

/// Stato di disponibilità di uno strumento da riga di comando (`brew`, `mas`).
enum ToolAvailability: Equatable {
    case available(path: String)
    case notInstalled
}
