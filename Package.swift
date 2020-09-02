// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "EnterpriseAppUpdater",
    platforms: [
        .iOS(.v10),
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
            dependencies: ["EnterpriseAppUpdater"]),
    ]
)
