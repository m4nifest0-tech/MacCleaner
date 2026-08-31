import Testing
@testable import PuliziaMac

struct AppThemeTests {
    @Test func colorSchemePreferenceMapsCorrectly() {
        #expect(ColorSchemePreference.system.colorScheme == nil)
        #expect(ColorSchemePreference.light.colorScheme != nil)
        #expect(ColorSchemePreference.dark.colorScheme != nil)
    }

    @Test func everyAccentThemeHasADisplayNameKey() {
        let keys = Set(AccentTheme.allCases.map(\.displayNameKey))
        #expect(keys.count == AccentTheme.allCases.count)
    }
}
