import Foundation

enum LoginItemScope: String {
    case user
    case system
}

struct LoginItem: Identifiable, Hashable {
    let id: URL // percorso del file .plist
    let label: String
    let programPath: String?
    let scope: LoginItemScope
    var plistPath: URL { id }
}
