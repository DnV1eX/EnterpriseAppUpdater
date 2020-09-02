//
//  EnterpriseAppUpdater.swift
//  EnterpriseAppUpdater
//
//  Created by Alexey Demin on 2019-09-09.
//  Copyright © 2019 DnV1eX. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import UIKit


/// Manage in-house application updates.
public class EnterpriseAppUpdater {

    public enum ManifestError: Error, CustomStringConvertible {
        case unableToLoad(Error)
        case unableToRead(Error)
        
        public var description: String {
            switch self {
            case .unableToLoad(let error): return "Unable to load manifest: \(error.localizedDescription)"
            case .unableToRead(let error): return "Unable to read manifest: \(error.localizedDescription)"
            }
        }
    }
    
    public enum ItemError: Error, CustomStringConvertible {
        case noItemsFound
        case multipleItemsFound(count: Int)
        case wrongBundleIdentifier(String)
        case unexpectedKind(String)
        case noBundleVersionFound
        case noAppUpdateNeeded(bundleVersion: String)
        case noIPAURLFound

        public var description: String {
            switch self {
            case .noItemsFound: return "No items found"
            case .multipleItemsFound(let count): return "\(count) items found, only single supported"
            case .wrongBundleIdentifier(let id): return "Bundle \"\(id)\" does not match the app"
            case .unexpectedKind(let kind): return "Unexpected kind \"\(kind)\", only \"software\" downloads supported"
            case .noBundleVersionFound: return "No bundle version found, it is required for software"
            case .noAppUpdateNeeded(let bundleVersion): return "Current app version is greater or equal \(bundleVersion), no update needed"
            case .noIPAURLFound: return "No .ipa URL found"
            }
        }
    }
    
    public enum URLError: Error, CustomStringConvertible {
        case unableToCreate(for: URL)
        case unableToOpen(URL)

        public var description: String {
            switch self {
            case .unableToCreate(let manifestURL): return "Unable to create URL for \"\(manifestURL)\""
            case .unableToOpen(let url): return "Unable to open URL \"\(url)\""
            }
        }
    }
    
    
    public struct Manifest: Decodable {
        
        public struct Item: Decodable {
            
            public struct Asset: Decodable {
                
                public enum Kind: String, Decodable {
                    case ipa = "software-package"
                    case icon = "display-image"
                    case image = "full-size-image"
                }
                
                public let kind: Kind
                public let url: String
            }
            
            public struct Metadata: Decodable {
                
                enum CodingKeys: String, CodingKey {
                    case identifier = "bundle-identifier"
                    case version = "bundle-version"
                    case kind
                    case title
                    case subtitle
                }
                
                public let identifier: String
                public let version: String?
                public let kind: String
                public let title: String
                public let subtitle: String?
            }
            
            public let assets: [Asset]
            public let metadata: Metadata
        }
        
        public let items: [Item]
    }
    
    
    public struct Message {
        public static var error = "App Update Error"
        public static var upToDate = "App is up-to-date"
        public static var available = "Update Available"
        public static var titleVersionCurrentVersion = "%@ version %@ (currently %@)"
        public static var start = "Download and Install Now"
        public static var postpone = "Remind to Update Later"
        public static var started = "User started the update"
        public static var postponed = "User postponed the update"
        public static var postponeWarning = "Immediate application update is highly encouraged!"
    }

    
    let manifestURL: URL
    let bundleIdentifier: String?
    let bundleVersion: String?
    
    
    public init(manifest url: URL, identifier: String? = Bundle.main.bundleIdentifier, version: String? = Bundle.main.version) {
        manifestURL = url
        bundleIdentifier = identifier
        bundleVersion = version
    }
    
    
    /// Load and read the application manifest file.
    public func loadManifest(onCompletion: @escaping (Result<Manifest, ManifestError>) -> Void) {
        
        DispatchQueue.global(qos: .utility).async {
            let result: Result<Manifest, ManifestError> = {
                let data: Data
                do {
                    data = try Data(contentsOf: self.manifestURL)
                } catch {
                    return .failure(.unableToLoad(error))
                }
//                print(String(data: data, encoding: .utf8))
                let manifest: Manifest
                do {
                    manifest = try PropertyListDecoder().decode(Manifest.self, from: data)
                } catch {
                    return .failure(.unableToRead(error))
                }
                return .success(manifest)
            }()
            DispatchQueue.main.async {
                onCompletion(result)
            }
        }
    }
    
    
    /// Check the manifest for an application update.
    public func check(manifest: Manifest, strict: Bool = true) -> Result<Manifest.Item, ItemError> {
        
        guard let item = manifest.items.first else {
            return .failure(.noItemsFound)
        }
        if strict {
            guard manifest.items.count == 1 else {
                return .failure(.multipleItemsFound(count: manifest.items.count))
            }
            guard bundleIdentifier == nil || item.metadata.identifier == bundleIdentifier else {
                return .failure(.wrongBundleIdentifier(item.metadata.identifier))
            }
            guard item.metadata.kind == "software" else {
                return .failure(.unexpectedKind(item.metadata.kind))
            }
        }
        guard let manifestBundleVersion = item.metadata.version else {
            return .failure(.noBundleVersionFound)
        }
        guard bundleVersion == nil || manifestBundleVersion > bundleVersion! else {
            return .failure(.noAppUpdateNeeded(bundleVersion: manifestBundleVersion))
        }
        guard let url = item.assets.first(where: { $0.kind == .ipa })?.url, !url.isEmpty else {
            return .failure(.noIPAURLFound)
        }
        return .success(item)
    }
    
    
    /// Start the application update.
    public func start(onError: ((URLError) -> Void)? = nil) {
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "itms-services"
        urlComponents.host = ""
        urlComponents.queryItems = [URLQueryItem(name: "action", value: "download-manifest"), URLQueryItem(name: "url", value: manifestURL.absoluteString)]
        if let url = urlComponents.url {
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
    public func alert(for item: Manifest.Item, onStart: ((UIAlertAction) -> Void)? = nil, onPostpone: ((UIAlertAction) -> Void)? = nil) -> UIAlertController {
        
        var message = String(format: Message.titleVersionCurrentVersion, item.metadata.title, item.metadata.version ?? "?", bundleVersion ?? "?")
        if let subtitle = item.metadata.subtitle {
            message += "\n\n\(subtitle.replacingOccurrences(of: "\\n", with: "\n"))"
        }
        let updateAlert = UIAlertController(title: Message.available, message: message, preferredStyle: .alert)
        let startAction = UIAlertAction(title: Message.start, style: .destructive, handler: onStart ?? { _ in self.start() })
        updateAlert.addAction(startAction)
        let postponeAction = UIAlertAction(title: Message.postpone, style: .cancel, handler: onPostpone)
        updateAlert.addAction(postponeAction)
        return updateAlert
    }
}



public extension Bundle {
    
    var version: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    
    var build: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
}
