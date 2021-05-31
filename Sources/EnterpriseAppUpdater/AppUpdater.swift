//
//  AppUpdater.swift
//  EnterpriseAppUpdater
//
//  Created by Alexey Demin on 2019-09-09.
//  Copyright © 2019 DnV1eX. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//

import Foundation

/// Manage in-house application updates.
public struct AppUpdater {
    
    let manifestURL: URL
    let bundleIdentifier: String?
    let bundleVersion: String?
    
    
    public init(manifest url: URL, identifier: String? = Bundle.main.bundleIdentifier, version: String? = Bundle.main.version) {
        manifestURL = url
        bundleIdentifier = identifier
        bundleVersion = version
    }
    
    
    public var url: URL? {
        var urlComponents = URLComponents()
        urlComponents.scheme = "itms-services"
        urlComponents.host = ""
        urlComponents.queryItems = [URLQueryItem(name: "action", value: "download-manifest"), URLQueryItem(name: "url", value: manifestURL.absoluteString)]
        return urlComponents.url
    }
    
    
    public func message(with metadata: Manifest.Item.Metadata) -> String {
        var message = String(format: Message.titleVersionCurrentVersion, metadata.title, metadata.version ?? "?", bundleVersion ?? "?")
        if let subtitle = metadata.subtitle {
            message += "\n\n\(subtitle.replacingOccurrences(of: "\\n", with: "\n"))"
        }
        return message
    }
    
    /// Load and read the application manifest file.
    public func loadManifest(in session: URLSession = .shared, onCompletion: @escaping (Result<Manifest, ManifestLoadError>) -> Void) {
        
        session.dataTask(with: manifestURL) { data, response, error in
            
            let result: Result<Manifest, ManifestLoadError> = {
                if let error = error {
                    return .failure(.connectionError(error))
                }
                if let response = response as? HTTPURLResponse {
                    guard case 200..<300 = response.statusCode else {
                        return .failure(.serverError(code: response.statusCode))
                    }
                }
                guard let data = data else {
                    return .failure(.noDataReceived)
                }
                let manifest: Manifest
                do {
                    manifest = try PropertyListDecoder().decode(Manifest.self, from: data)
                } catch {
                    return .failure(.decodingError(error))
                }
                return .success(manifest)
            }()
            DispatchQueue.main.async {
                onCompletion(result)
            }
        }.resume()
    }
    
    /// Check the manifest for an application update.
    public func check(manifest: Manifest, strict: Bool = true) -> Result<Manifest.Item, ManifestCheckError> {
        
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
}



public extension AppUpdater {
    
    enum ManifestLoadError: Error, CustomStringConvertible {
        case connectionError(Error)
        case serverError(code: Int)
        case noDataReceived
        case decodingError(Error)
        
        public var description: String {
            switch self {
            case .connectionError(let error): return error.localizedDescription
            case .serverError(let code): return "Server error \(code)"
            case .noDataReceived: return "Response data is empty"
            case .decodingError(let error): return error.localizedDescription
            }
        }
    }
    
    
    enum ManifestCheckError: Error, CustomStringConvertible {
        case noItemsFound
        case multipleItemsFound(count: Int)
        case wrongBundleIdentifier(String)
        case unexpectedKind(String)
        case noBundleVersionFound
        case noAppUpdateNeeded(bundleVersion: String)
        case noIPAURLFound

        public var description: String {
            switch self {
            case .noItemsFound: return "No manifest items found"
            case .multipleItemsFound(let count): return "\(count) manifest items found, only single supported"
            case .wrongBundleIdentifier(let id): return "Bundle \"\(id)\" does not match the app"
            case .unexpectedKind(let kind): return "Unexpected kind \"\(kind)\", only \"software\" downloads supported"
            case .noBundleVersionFound: return "No bundle version found, it is required for software"
            case .noAppUpdateNeeded(let bundleVersion): return "Current app version is greater or equal \(bundleVersion), no update needed"
            case .noIPAURLFound: return "No .ipa URL found"
            }
        }
    }
    
    
    enum URLError: Error, CustomStringConvertible {
        case unableToCreate(for: URL)
        case unableToOpen(URL)

        public var description: String {
            switch self {
            case .unableToCreate(let manifestURL): return "Unable to create URL for \"\(manifestURL)\""
            case .unableToOpen(let url): return "Unable to open URL \"\(url)\""
            }
        }
    }
}



public extension AppUpdater {
    
    struct Manifest: Decodable {
        
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
}



public extension AppUpdater {
    
    struct Message {
        public static var error = "App Update Error"
        public static var noConnection = "No internet or server connection"
        public static var upToDate = "App is up-to-date"
        public static var available = "Update Available"
        public static var titleVersionCurrentVersion = "%@ version %@ (currently %@)"
        public static var start = "Download and Install Now"
        public static var postpone = "Remind to Update Later"
        public static var started = "User started the update"
        public static var postponed = "User postponed the update"
        public static var postponeWarning = "Immediate application update is highly encouraged!"
    }
}



public extension Bundle {
    
    var version: String? {
        infoDictionary?["CFBundleShortVersionString"] as? String
    }
    
    var build: String? {
        infoDictionary?["CFBundleVersion"] as? String
    }
}



@available(*, deprecated, renamed: "AppUpdater")
public typealias EnterpriseAppUpdater = AppUpdater
