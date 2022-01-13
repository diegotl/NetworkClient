// swift-tools-version:5.4

import PackageDescription

let package = Package(
    name: "NetworkClient",
    platforms: [
        .macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6)
    ],
    products: [
        .library(name: "NetworkClientCombine", targets: ["NetworkClient"]),
    ],
    targets: [
        .target(name: "NetworkClient", path: "Sources"),
        .testTarget(name: "NetworkClientTests", dependencies: ["NetworkClient"]),
    ]
)
