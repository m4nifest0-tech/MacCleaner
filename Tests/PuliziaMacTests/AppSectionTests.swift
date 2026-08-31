import Testing
@testable import PuliziaMac

struct AppSectionTests {
    @Test func allSectionsHaveTitleKeys() {
        for section in AppSection.allCases {
            #expect(!section.titleKey.isEmpty)
        }
    }

    @Test func allSectionTitleKeysAreLocalized() {
        for section in AppSection.allCases {
            for language in AppLanguage.allCases {
                #expect(Localization.string(section.titleKey, language: language) != section.titleKey)
            }
        }
    }
}
