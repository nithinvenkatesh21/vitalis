// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VitalisHealthKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "VitalisHealthKit",
            targets: ["VitalisHealthKit"]),
    ],
    dependencies: [
        .package(path: "../VitalisCore")
    ],
    targets: [
        .target(
            name: "VitalisHealthKit",
            dependencies: [
                .product(name: "VitalisCore", package: "VitalisCore")
            ]),
        .testTarget(
            name: "VitalisHealthKitTests",
            dependencies: ["VitalisHealthKit"]),
    ]
)
