// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SwiftEmbedSDK",
    platforms: [
        .iOS(.v14), .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "SwiftEmbedSDK",
            targets: ["SwiftEmbedSDK"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/Flight-School/AnyCodable.git", from: "0.6.7")
    ],
    targets: [
        .target(
            name: "SwiftEmbedSDK",
            dependencies: [
                .product(name: "AnyCodable", package: "AnyCodable")
            ],
            path: "Sources/SwiftEmbedSDK",
            exclude: [],
            resources: [],
            swiftSettings: [
            ]
        ),
        .testTarget(
            name: "SwiftEmbedSDKTests",
            dependencies: ["SwiftEmbedSDK"],
            path: "SwiftEmbedSDKTests"
        ),
    ]
)

