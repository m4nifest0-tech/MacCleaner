import Foundation
import Testing
@testable import PuliziaMac

struct LoginItemsServiceTests {
    @Test func displayNameUsesLastReverseDNSComponent() {
        let item = LoginItem(id: URL(fileURLWithPath: "/tmp/com.adobe.ARM.plist"), label: "com.adobe.ARM", programPath: nil, scope: .user)
        #expect(LoginItemsService.displayName(for: item) == "ARM")
    }

    @Test func displayNameFallsBackToFullLabelWhenNoDots() {
        let item = LoginItem(id: URL(fileURLWithPath: "/tmp/helper.plist"), label: "helper", programPath: nil, scope: .user)
        #expect(LoginItemsService.displayName(for: item) == "helper")
    }

    @Test func appBundleURLResolvesPathInsideAppBundle() throws {
        let fm = FileManager.default
        let appURL = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".app")
        try fm.createDirectory(at: appURL.appendingPathComponent("Contents/MacOS"), withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: appURL) }

        let programPath = appURL.appendingPathComponent("Contents/MacOS/Helper").path
        let item = LoginItem(id: URL(fileURLWithPath: "/tmp/x.plist"), label: "x", programPath: programPath, scope: .user)

        #expect(LoginItemsService.appBundleURL(for: item)?.path == appURL.path)
    }

    @Test func appBundleURLReturnsNilWhenProgramPathHasNoAppBundle() {
        let item = LoginItem(id: URL(fileURLWithPath: "/tmp/x.plist"), label: "x", programPath: "/usr/local/bin/helper", scope: .user)
        #expect(LoginItemsService.appBundleURL(for: item) == nil)
    }

    @Test func appBundleURLReturnsNilWhenProgramPathMissing() {
        let item = LoginItem(id: URL(fileURLWithPath: "/tmp/x.plist"), label: "x", programPath: nil, scope: .user)
        #expect(LoginItemsService.appBundleURL(for: item) == nil)
    }
}
