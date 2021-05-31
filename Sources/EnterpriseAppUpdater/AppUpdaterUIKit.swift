//
//  AppUpdaterUIKit.swift
//  EnterpriseAppUpdater
//
//  Created by Alexey Demin on 2021-05-27.
//  Copyright © 2021 DnV1eX. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//

#if canImport(UIKit)
import UIKit

@available(iOS 10.0, *)
public extension AppUpdater {
    /// Start the application update.
    func start(onError: ((URLError) -> Void)? = nil) {
        
        if let url = url {
            UIApplication.shared.open(url) { success in
                if !success {
                    onError?(.unableToOpen(url))
                }
            }
        } else {
            onError?(.unableToCreate(for: manifestURL))
        }
    }
    
    /// Provides an alert with update information.
    func alert(for item: Manifest.Item, onStart: ((UIAlertAction) -> Void)? = nil, onPostpone: ((UIAlertAction) -> Void)? = nil) -> UIAlertController {
        
        let updateAlert = UIAlertController(title: Message.available, message: message(with: item.metadata), preferredStyle: .alert)
        let startAction = UIAlertAction(title: Message.start, style: .destructive, handler: onStart ?? { _ in self.start() })
        updateAlert.addAction(startAction)
        let postponeAction = UIAlertAction(title: Message.postpone, style: .cancel, handler: onPostpone)
        updateAlert.addAction(postponeAction)
        return updateAlert
    }
}
#endif
