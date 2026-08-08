// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "TinyStockCore",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v26),
        .watchOS(.v26),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "TinyStockCore",
            targets: ["TinyStockCore"]
        ),
    ],
    targets: [
        .target(
            name: "TinyStockCore",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "TinyStockCoreTests",
            dependencies: ["TinyStockCore"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
