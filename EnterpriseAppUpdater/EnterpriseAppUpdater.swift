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


public class EnterpriseAppUpdater {

    public enum Error: LocalizedError {
        case unableToLoadManifest(reason: String)
        case unableToReadManifest(reason: String)
        case misformattedManifest(description: String)
        case wrongManifestBundleIdentifier(String)
        case noAppUpdateNeeded(manifestBundleVersion: String)
        case unableToCreateDownloadLink(String)
        case unableToOpenDownloadLink(String)

        public var errorDescription: String? {
            switch self {
            case .unableToLoadManifest: return "Unable to load manifest"
            case .unableToReadManifest: return "Unable to read manifest"
            case .misformattedManifest: return "Manifest is misformatted"
            case .wrongManifestBundleIdentifier: return "Wrong manifest bundle identifier"
            case .noAppUpdateNeeded: return "App is up-to-date"
            case .unableToCreateDownloadLink: return "Unable to create download link"
            case .unableToOpenDownloadLink: return "Unable to open download link"
            }
        }
        
        public var failureReason: String? {
            switch self {
            case .unableToLoadManifest(let reason): return reason
            case .unableToReadManifest(let reason): return reason
            case .misformattedManifest(let description): return description
            case .wrongManifestBundleIdentifier(let id): return "Bundle \"\(id)\" does not match the app."
            case .noAppUpdateNeeded(let version): return "Current app version is greater or equal \(version), no update needed."
            case .unableToCreateDownloadLink(let query): return "Invalid URL components \"\(query)\"."
            case .unableToOpenDownloadLink(let path): return "Invalid URL \"\(path)\"."
            }
        }
        
        public var localizedDescription: String {
            return (errorDescription ?? "App Update Error") + (failureReason.map { ": \($0)" } ?? ".")
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
    
    
    public static let loadManifestErrorMessage = "App Update Manifest Load Error"
    public static let checkErrorMessage = "App Update Check Error"
    public static let startErrorMessage = "App Update Start Error"
//    public static let postponeWarningMessage = "Immediate application update is highly encouraged!"

    let manifestURL: URL
    let bundleIdentifier: String?
    let bundleVersion: String?
    
    
    public init(manifest url: URL, identifier: String? = Bundle.main.bundleIdentifier, version: String? = Bundle.main.version) {
        manifestURL = url
        bundleIdentifier = identifier
        bundleVersion = version
    }
    
    
    public func loadManifest(onCompletion: @escaping (Result<Manifest, Error>) -> Void) {
        
        DispatchQueue.global(qos: .utility).async {
            let result: Result<Manifest, Error> = {
                let data: Data
                do {
                    data = try Data(contentsOf: self.manifestURL)
                } catch {
                    return .failure(.unableToLoadManifest(reason: error.localizedDescription))
                }
//                print(String(data: data, encoding: .utf8))
                let manifest: Manifest
                do {
                    manifest = try PropertyListDecoder().decode(Manifest.self, from: data)
                } catch {
                    return .failure(.unableToReadManifest(reason: error.localizedDescription))
                }
                return .success(manifest)
            }()
            DispatchQueue.main.async {
                onCompletion(result)
            }
        }
    }
    
    
    public func check(manifest: Manifest) -> Result<Manifest.Item, Error> {
        
        guard let item = manifest.items.first else {
            return .failure(.misformattedManifest(description: "No items found."))
        }
        guard manifest.items.count == 1 else {
            return .failure(.misformattedManifest(description: "\(manifest.items.count) items found, only single supported."))
        }
        guard bundleIdentifier == nil || item.metadata.identifier == bundleIdentifier else {
            return .failure(.wrongManifestBundleIdentifier(item.metadata.identifier))
        }
        guard item.metadata.kind == "software" else {
            return .failure(.misformattedManifest(description: "Unexpected \"\(item.metadata.kind)\" kind, only \"software\" downloads supported."))
        }
        guard let manifestBundleVersion = item.metadata.version else {
            return .failure(.misformattedManifest(description: "No bundle version found, it is required for software."))
        }
        guard bundleVersion == nil || manifestBundleVersion > bundleVersion! else {
            return .failure(.noAppUpdateNeeded(manifestBundleVersion: manifestBundleVersion))
        }
        guard let url = item.assets.first(where: { $0.kind == .ipa })?.url, !url.isEmpty else {
            return .failure(.misformattedManifest(description: "No ipa URL found."))
        }
        return .success(item)
    }
    
    
    public func start(onError: ((Error) -> Void)? = nil) {
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "itms-services"
        urlComponents.host = ""
        urlComponents.queryItems = [URLQueryItem(name: "action", value: "download-manifest"), URLQueryItem(name: "url", value: manifestURL.absoluteString)]
        if let url = urlComponents.url {
            UIApplication.shared.open(url) { success in
                if !success {
                    onError?(.unableToOpenDownloadLink(url.absoluteString))
                }
            }
        } else {
            onError?(.unableToCreateDownloadLink(urlComponents.query ?? ""))
        }
    }

    
    public func alert(for item: Manifest.Item, onStart: ((UIAlertAction) -> Void)? = nil, onPostpone: ((UIAlertAction) -> Void)? = nil) -> UIAlertController {
        
        var message: String
        if let version = item.metadata.version {
            message = "\(item.metadata.title) version \(version) is available" + (bundleVersion.map { " (currently \($0))." } ?? ".")
        } else {
            message = "New version of \(item.metadata.title) is available."
        }
        if let subtitle = item.metadata.subtitle {
            message += "\n\n\(subtitle.replacingOccurrences(of: "\\n", with: "\n"))"
        }
        let updateAlert = UIAlertController(title: "App Update Required", message: message, preferredStyle: .alert)
        let startAction = UIAlertAction(title: "Download and Install Now", style: .destructive, handler: onStart ?? { _ in self.start() })
        updateAlert.addAction(startAction)
        let postponeAction = UIAlertAction(title: "Remind to Update Later", style: .cancel, handler: onPostpone)
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
