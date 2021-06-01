//
//  AppUpdaterSwiftUI.swift
//  EnterpriseAppUpdater
//
//  Created by Alexey Demin on 2021-05-27.
//  Copyright © 2021 DnV1eX. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//

#if canImport(SwiftUI) && canImport(Combine)
import SwiftUI

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension AppUpdater {
    /// Provides an alert with update information.
    func alert(for item: Manifest.Item, onStart: @escaping (URL) -> Void, onPostpone: @escaping () -> Void = { }) -> Alert {
        
        Alert(title: Text(Message.available),
              message: Text(message(with: item.metadata)),
              primaryButton: .destructive(Text(Message.start), action: { url.map(onStart) }),
              secondaryButton: .cancel(Text(Message.postpone), action: onPostpone))
    }
}


extension AppUpdater.Manifest.Item: Identifiable {
    public var id: String {
        metadata.identifier + (metadata.version ?? "")
    }
}
#endif
