// swift-tools-version: 5.5.0
import PackageDescription

let package = Package(
    name: "Beet",
    platforms: [.iOS(.v11), .macOS(.v10_12)],
    products: [
        .library(
            name: "Beet",
            targets: ["Beet"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Beet",
            dependencies: []),
        .testTarget(
            name: "BeetTests",
            dependencies: ["Beet"],
            resources: [ .process("Resources")]),
    ]
)
