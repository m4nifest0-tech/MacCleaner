import Testing
@testable import PuliziaMac

struct LocalizationTests {
    @Test func knownKeyDiffersByLanguage() {
        let it = Localization.string("sidebar.cacheCleaner", language: .italian)
        let en = Localization.string("sidebar.cacheCleaner", language: .english)
        #expect(it == "Cache e File Temporanei")
        #expect(en == "Cache & Temp Files")
        #expect(it != en)
    }

    @Test func unknownKeyFallsBackToKeyItself() {
        #expect(Localization.string("this.key.does.not.exist", language: .italian) == "this.key.does.not.exist")
    }

    @Test func allAppSectionAndCategoryKeysAreNonEmptyInBothLanguages() {
        let keys = AppSection.allCases.map(\.titleKey) + CleanableCategory.allCases.map(\.titleKey)
        for key in keys {
            for language in AppLanguage.allCases {
                let value = Localization.string(key, language: language)
                #expect(!value.isEmpty)
                #expect(value != key, "Manca la traduzione per la chiave \(key) (\(language))")
            }
        }
    }

    @Test func allAccentThemeNamesAreLocalized() {
        for theme in AccentTheme.allCases {
            for language in AppLanguage.allCases {
                #expect(Localization.string(theme.displayNameKey, language: language) != theme.displayNameKey)
            }
        }
    }
}
