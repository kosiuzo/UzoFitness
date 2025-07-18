// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UzoFitnessCore",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "UzoFitnessCore",
            targets: ["UzoFitnessCore"]
        ),
    ],
    dependencies: [
        // Add any external dependencies here
    ],
    targets: [
        .target(
            name: "UzoFitnessCore",
            dependencies: []
        ),
        .testTarget(
            name: "UzoFitnessCoreTests",
            dependencies: ["UzoFitnessCore"]
        ),
    ]
)