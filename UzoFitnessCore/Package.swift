// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UzoFitnessCore",
    platforms: [
        .iOS(.v17), // <-- Set minimum to iOS 17
        .watchOS(.v10) // or whatever is appropriate
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "UzoFitnessCore",
            targets: ["UzoFitnessCore"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "UzoFitnessCore"),
        .testTarget(
            name: "UzoFitnessCoreTests",
            dependencies: ["UzoFitnessCore"]
        ),
    ]
)
