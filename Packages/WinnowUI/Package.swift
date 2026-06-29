// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WinnowUI",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
    ],
    products: [
        .library(name: "WinnowUI", targets: ["WinnowUI"]),
    ],
    dependencies: [
        .package(path: "../WinnowCore"),
    ],
    targets: [
        .target(
            name: "WinnowUI",
            dependencies: ["WinnowCore"],
            path: "Sources/WinnowUI"
        ),
        .testTarget(
            name: "WinnowUITests",
            dependencies: ["WinnowUI"],
            path: "Tests/WinnowUITests"
        ),
    ],
    swiftLanguageModes: [.v6]
)
