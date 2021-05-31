//
//  AppUpdaterCombine.swift
//  EnterpriseAppUpdater
//
//  Created by Alexey Demin on 2021-05-27.
//  Copyright © 2021 DnV1eX. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//

#if canImport(Combine)
import Combine
import Foundation

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension AppUpdater {
    
    var publisher: AnyPublisher<Manifest.Item, Error> {
        publisher()
    }
    
    
    func publisher(using session: URLSession = .shared, strictCheck: Bool = true) -> AnyPublisher<Manifest.Item, Error> {
        Deferred {
            Future { promise in
                loadManifest(in: session) { result in
                    do {
                        try promise(.success(check(manifest: result.get(), strict: strictCheck).get()))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
#endif
