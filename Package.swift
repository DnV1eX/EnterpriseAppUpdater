// swift-tools-version:5.4

import PackageDescription

let package = Package(
    name: "EnterpriseAppUpdater",
    products: [
        .library(
            name: "EnterpriseAppUpdater",
            targets: ["EnterpriseAppUpdater"]),
    ],
    targets: [
        .target(
            name: "EnterpriseAppUpdater",
            dependencies: []),
        .testTarget(
            name: "EnterpriseAppUpdaterTests",
            dependencies: ["EnterpriseAppUpdater"],
            resources: [.copy("manifest.plist")]),
    ]
)
