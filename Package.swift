// swift-tools-version:5.4

import PackageDescription

let package = Package(
    name: "EnterpriseAppUpdater",
    platforms: [
        .iOS(.v10),
        .macOS(.v10_12),
        .tvOS(.v10),
        .watchOS(.v3),
    ],
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
