// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WhenKit",
    platforms: [
        .iOS(.v12),
        .macOS(.v10_14),
        .tvOS(.v12),
        .watchOS(.v5)
    ],
    products: [
        .library(
            name: "WhenKit",
            targets: ["WhenKit"]
        )
    ],
    targets: [
        .target(
            name: "WhenKit",
            path: "Sources/WhenKit"
        ),
        .testTarget(
            name: "WhenKitTests",
            dependencies: ["WhenKit"],
            path: "Tests/WhenKitTests"
        )
    ]
)
