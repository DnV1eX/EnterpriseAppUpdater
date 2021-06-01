//
//  AppUpdaterTests.swift
//  EnterpriseAppUpdater
//
//  Created by Alexey Demin on 2019-09-09.
//  Copyright © 2019 DnV1eX. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//

import XCTest
import EnterpriseAppUpdater


let url = URL(fileURLWithPath: #file).deletingLastPathComponent().appendingPathComponent("manifest", isDirectory: false).appendingPathExtension("plist")


final class AppUpdaterTests: XCTestCase {

    func testManifest() throws {
        
        let updater = AppUpdater(manifest: url, identifier: "test", version: "1.0.0")
        let loadManifestExpectation = expectation(description: "loadManifest")
        var loadManifestResult: Result<AppUpdater.Manifest, AppUpdater.ManifestLoadError>?
        updater.loadManifest {
            loadManifestResult = $0
            loadManifestExpectation.fulfill()
        }
        waitForExpectations(timeout: 1)
        
        guard let manifest = try loadManifestResult?.get() else { return }
        
        let item = try updater.check(manifest: manifest).get()
        XCTAssertEqual(item.assets.first { $0.kind == .ipa }?.url, "https://")
    }
}


#if canImport(UIKit)
import UIKit

@available(iOS 10.0, *)
extension AppUpdaterTests {
    
    func testUIKit() throws {
        
        let loadManifestExpectation = expectation(description: "loadManifest")

        let updater = AppUpdater(manifest: url, identifier: "test", version: "0")
        updater.loadManifest { result in
            switch result {
            case .success(let manifest):
                switch updater.check(manifest: manifest) {
                case .success(let item):
                    print(AppUpdater.Message.available, item.metadata.version ?? "?")
                    let alert = updater.alert(for: item) { _ in
                        print(AppUpdater.Message.started, item.metadata.version ?? "?")
                        updater.start { error in
                            print(AppUpdater.Message.error, error)
                        }
                    } onPostpone: { _ in
                        print(AppUpdater.Message.postponed, item.metadata.version ?? "?")
                    }
                    XCTAssertEqual(item.metadata.identifier, "test")
                    XCTAssertEqual(alert.title, "Update Available")
                case .failure(let error):
                    switch error {
                    case .noAppUpdateNeeded:
                        print(AppUpdater.Message.upToDate, error)
                    default:
                        print(AppUpdater.Message.error, error)
                    }
                }
            case .failure(let error):
                switch error {
                case .connectionError:
                    print(AppUpdater.Message.noConnection, error)
                default:
                    print(AppUpdater.Message.error, error)
                }
            }
            loadManifestExpectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
}
#endif



#if canImport(SwiftUI) && canImport(Combine)
import SwiftUI

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension AppUpdaterTests {
    
    func testSwiftUI() throws {
        
        let loadManifestExpectation = expectation(description: "loadManifest")

        let updater = AppUpdater(manifest: url, identifier: "test", version: "0")
        var item: AppUpdater.Manifest.Item? {
            didSet {
                guard let item = item else { return }
                
                let alert = updater.alert(for: item) { url in
                    print(AppUpdater.Message.started, item.metadata.version ?? "?")
                } onPostpone: {
                    print(AppUpdater.Message.postponed, item.metadata.version ?? "?")
                }
                XCTAssertEqual(item.metadata.identifier, "test")
                XCTAssert("\(alert)".contains("Update Available"))
                loadManifestExpectation.fulfill()
            }
        }
        let subscription = updater.publisher
            .handleEvents(receiveOutput: { item in
                print(AppUpdater.Message.available, item.metadata.version ?? "?")
            }, receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    switch error {
                    case AppUpdater.ManifestLoadError.connectionError:
                        print(AppUpdater.Message.noConnection, error)
                    case AppUpdater.ManifestCheckError.noAppUpdateNeeded:
                        print(AppUpdater.Message.upToDate, error)
                    default:
                        print(AppUpdater.Message.error, error)
                    }
                }
            })
            .map(Optional.init)
            .replaceError(with: nil)
            .sink { item = $0 }

        waitForExpectations(timeout: 1)
        _ = subscription
    }
}
#endif
