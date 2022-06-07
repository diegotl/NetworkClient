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
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
    ],
    targets: [
        .target(name: "NetworkClient", dependencies: [
            .product(name: "Logging", package: "swift-log")
        ], path: "Sources"),
        .testTarget(name: "NetworkClientTests", dependencies: ["NetworkClient"]),
    ]
)
