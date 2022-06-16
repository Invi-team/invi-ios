// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "InviAuthenticator",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "InviAuthenticator",
            targets: ["InviAuthenticator"])
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-case-paths.git", from: "0.4.0"),
        .package(name: "WebService", path: "../WebService")
    ],
    targets: [
        .target(
            name: "InviAuthenticator",
            dependencies: ["WebService", .product(name: "CasePaths", package: "swift-case-paths")]),
        .testTarget(
            name: "InviAuthenticatorTests",
            dependencies: ["InviAuthenticator", .product(name: "WebServiceTestHelpers", package: "WebService")])
    ]
)
