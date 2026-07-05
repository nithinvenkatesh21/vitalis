// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VitalisPersistence",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "VitalisPersistence",
            targets: ["VitalisPersistence"]),
    ],
    dependencies: [
        .package(path: "../VitalisCore"),
        .package(path: "../VitalisNetworking")
    ],
    targets: [
        .target(
            name: "VitalisPersistence",
            dependencies: [
                .product(name: "VitalisCore", package: "VitalisCore"),
                .product(name: "VitalisNetworking", package: "VitalisNetworking")
            ]),
        .testTarget(
            name: "VitalisPersistenceTests",
            dependencies: ["VitalisPersistence"]),
    ]
)
