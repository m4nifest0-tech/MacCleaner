import Foundation
import Testing
@testable import PuliziaMac

struct AppSettingsTests {
    private func freshDefaults() -> UserDefaults {
        let suiteName = "PuliziaMacTests.\(UUID().uuidString)"
        return UserDefaults(suiteName: suiteName)!
    }

    @Test func defaultsToItalianSystemAppearanceAndBlueAccent() {
        let settings = AppSettings(defaults: freshDefaults())
        #expect(settings.language == .italian)
        #expect(settings.colorSchemePreference == .system)
        #expect(settings.accentTheme == .blue)
    }

    @Test func persistsChangesAcrossInstances() {
        let defaults = freshDefaults()
        let first = AppSettings(defaults: defaults)
        first.language = .english
        first.colorSchemePreference = .dark
        first.accentTheme = .purple

        let second = AppSettings(defaults: defaults)
        #expect(second.language == .english)
        #expect(second.colorSchemePreference == .dark)
        #expect(second.accentTheme == .purple)
    }

    @Test func tReflectsCurrentLanguage() {
        let settings = AppSettings(defaults: freshDefaults())
        settings.language = .italian
        #expect(settings.t("sidebar.cacheCleaner") == "Cache e File Temporanei")
        settings.language = .english
        #expect(settings.t("sidebar.cacheCleaner") == "Cache & Temp Files")
    }
}
