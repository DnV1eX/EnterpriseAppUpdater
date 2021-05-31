# EnterpriseAppUpdater
Enterprise App Updater loads app's manifest file, checks for a new version, provides an alert with patch notes and starts the update.

<div align="center"><img src="Screenshot.png" width="300"></div>


## Setup
### Swift Package Manager
Open your application project in Xcode 11 or later, go to menu `File -> Swift Packages -> Add Package Dependency...` and paste the package repository URL `https://github.com/DnV1eX/EnterpriseAppUpdater.git`.

### CocoaPods *(deprecated)*
Add the pod to your `Podfile`:
```ruby
pod 'EnterpriseAppUpdater', '~> 1.2'
```


## Prepare Application Manifest
1. Generate `manifest.plist` during enterprise app distribution in Xcode Organizer;
2. Make sure `software-package` asset contains direct **https** link to the app's **.ipa**;
3. Optionally add release notes to `subtitle` metadata to display in the update alert *(use `\n` for line break)*;
4. Upload the manifest and get a direct **https** link you will use to initialize AppUpdater.

> Manifest URL must remain the same when the update is released, you only edit **.plist** content such as app `url`, `bundle-version` and optional `subtitle`.


## Usage Example
```swift
import EnterpriseAppUpdater
```
### SwiftUI
```swift
class Model: ObservableObject {
    
    let updater = AppUpdater(manifest: url) // Initialize AppUpdater with manifest.plist URL.
    @Published var manifestItem: AppUpdater.Manifest.Item?
    
    func checkForUpdate() {
        updater.publisher
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
            .assign(to: &$manifestItem)
    }
}

struct MyApp: App {
    
    @StateObject fileprivate var model = Model()
    @Environment(\.openURL) private var openURL
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .alert(item: $model.manifestItem) { item in
                    //model.updater.alert(for: item, onStart: openURL.callAsFunction)
                    model.updater.alert(for: item) { url in
                        print(AppUpdater.Message.started, item.metadata.version ?? "?")
                        openURL(url) { success in
                            if !success {
                                print(AppUpdater.Message.error, AppUpdater.URLError.unableToOpen(url))
                            }
                        }
                    } onPostpone: {
                        print(AppUpdater.Message.postponed, item.metadata.version ?? "?")
                    }
                }
                .onAppear {
                    model.checkForUpdate()
                }
        }
    }
}
```
### UIKit
```swift
class AppDelegate: UIResponder, UIApplicationDelegate {

    let updater = AppUpdater(manifest: url) // Initialize AppUpdater with manifest.plist URL.
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        checkForUpdate(application)
        return true
    }
    
    func checkForUpdate(_ application: UIApplication) {
        updater.loadManifest { result in
            switch result {
            case .success(let manifest):
                switch updater.check(manifest: manifest) {
                case .success(let item):
                    print(AppUpdater.Message.available, item.metadata.version ?? "?")
                    //let alert = updater.alert(for: item)
                    let alert = updater.alert(for: item) { _ in
                        print(AppUpdater.Message.started, item.metadata.version ?? "?")
                        updater.start { error in
                            print(AppUpdater.Message.error, error)
                        }
                    } onPostpone: { _ in
                        print(AppUpdater.Message.postponed, item.metadata.version ?? "?")
                    }
                    application.windows.first?.rootViewController?.present(alert, animated: true)
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
        }
    }
}
```

> It's up to you whether to load manifest and check for update on the app launch, at time intervals, or by user request.
> A good practise is to check for update when the app becomes active, if the specified time has passed since the last check.


## License
Copyright © 2019-2021 DnV1eX. All rights reserved.
Licensed under the Apache License, Version 2.0.
