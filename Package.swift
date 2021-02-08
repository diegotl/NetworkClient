// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "APIClient",
    platforms: [
        .macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6)
    ],
    products: [
        .library(name: "APIClientCombine", targets: ["APIClient"]),
    ],
    targets: [
        .target(name: "APIClient", path: "Sources"),
        .testTarget(name: "APIClientTests", dependencies: ["APIClient"]),
    ]
)
