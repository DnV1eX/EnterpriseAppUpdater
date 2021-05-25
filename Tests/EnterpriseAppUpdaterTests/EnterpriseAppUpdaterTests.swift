//
//  EnterpriseAppUpdaterTests.swift
//  EnterpriseAppUpdater
//
//  Created by Alexey Demin on 2019-09-09.
//  Copyright © 2019 DnV1eX. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//

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
