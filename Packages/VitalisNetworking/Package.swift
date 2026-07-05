// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VitalisNetworking",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "VitalisNetworking",
            targets: ["VitalisNetworking"]),
    ],
    dependencies: [
        .package(path: "../VitalisCore")
    ],
    targets: [
        .target(
            name: "VitalisNetworking",
            dependencies: [
                .product(name: "VitalisCore", package: "VitalisCore")
            ]),
        .testTarget(
            name: "VitalisNetworkingTests",
            dependencies: ["VitalisNetworking"]),
    ]
)
