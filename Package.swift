// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LivriaSocial",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "LivriaSocial",
            targets: ["LivriaSocial"]
        )
    ],
    targets: [
        .target(
            name: "LivriaSocial",
            path: "Sources"
        )
    ]
)
