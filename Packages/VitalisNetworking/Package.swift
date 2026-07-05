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
        .package(path: "../VitalisCore"),
        .package(url: "https://github.com/supabase-community/supabase-swift.git", from: "2.22.0")
    ],
    targets: [
        .target(
            name: "VitalisNetworking",
            dependencies: [
                .product(name: "VitalisCore", package: "VitalisCore"),
                .product(name: "Supabase", package: "supabase-swift")
            ]),
        .testTarget(
            name: "VitalisNetworkingTests",
            dependencies: ["VitalisNetworking"]),
    ]
)
