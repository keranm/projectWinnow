// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WinnowCore",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
    ],
    products: [
        .library(name: "WinnowCore", targets: ["WinnowCore"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "WinnowCore",
            dependencies: [],
            path: "Sources/WinnowCore"
        ),
        .testTarget(
            name: "WinnowCoreTests",
            dependencies: ["WinnowCore"],
            path: "Tests/WinnowCoreTests"
        ),
    ],
    swiftLanguageModes: [.v6]
)
