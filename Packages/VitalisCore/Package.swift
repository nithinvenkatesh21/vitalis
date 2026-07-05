// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VitalisCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "VitalisCore",
            targets: ["VitalisCore"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "VitalisCore",
            dependencies: []),
        .testTarget(
            name: "VitalisCoreTests",
            dependencies: ["VitalisCore"]),
    ]
)
