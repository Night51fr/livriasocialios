// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LivriaMarketplace",
    defaultLocalization: "fr",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "LivriaMarketplace",
            targets: ["LivriaMarketplace"]
        )
    ],
    targets: [
        .target(
            name: "LivriaMarketplace",
            path: "Sources",
            resources: [
                .process("Assets.xcassets")
            ]
        )
    ]
)
