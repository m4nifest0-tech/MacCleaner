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

    @Test func keyboardShortcutsAreUniqueAndSequential() {
        let assigned = AppSection.allCases.compactMap(\.keyboardShortcutKey)
        #expect(Set(assigned).count == assigned.count, "Ogni scorciatoia numerica deve comparire una sola volta")
        #expect(assigned == Array("123456789".prefix(assigned.count)))
    }

    @Test func dashboardIsAlwaysCmd1() {
        #expect(AppSection.dashboard.keyboardShortcutKey == "1")
    }

    @Test func everySectionHasNonEmptySearchKeywords() {
        for section in AppSection.allCases {
            #expect(!section.searchKeywords.isEmpty)
        }
    }

    @Test func matchesFindsSectionBySynonym() {
        #expect(AppSection.duplicateFinder.matches(query: "doppi"))
        #expect(AppSection.mailAttachments.matches(query: "posta"))
        #expect(!AppSection.mailAttachments.matches(query: "duplicati"))
    }

    @Test func matchesIsCaseInsensitive() {
        #expect(AppSection.updateManager.matches(query: "HOMEBREW"))
    }
}
