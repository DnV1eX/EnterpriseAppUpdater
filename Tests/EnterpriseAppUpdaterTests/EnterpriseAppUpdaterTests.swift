import XCTest
@testable import EnterpriseAppUpdater

typealias Updater = EnterpriseAppUpdater


final class EnterpriseAppUpdaterTests: XCTestCase {
    
    let manifestURL = URL(fileURLWithPath: #file).deletingLastPathComponent().appendingPathComponent("manifest", isDirectory: false).appendingPathExtension("plist")
    
    func testManifest() throws {
        let updater = Updater(manifest: manifestURL, identifier: "test", version: "1.0.0")
        let loadManifestExpectation = expectation(description: "loadManifest")
        var loadManifestResult: Result<Updater.Manifest, Updater.ManifestError>!
        updater.loadManifest {
            loadManifestResult = $0
            loadManifestExpectation.fulfill()
        }
        waitForExpectations(timeout: 1)
        
        let manifest = try loadManifestResult.get()
        let item = try updater.check(manifest: manifest).get()
        XCTAssertEqual(item.assets.first { $0.kind == .ipa }?.url, "https://")
    }
}
