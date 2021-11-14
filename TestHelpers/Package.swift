// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TestHelpers",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "TestHelpers",
            targets: ["TestHelpers"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "TestHelpers",
            dependencies: [])
    ]
)
