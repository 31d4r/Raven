// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RTextExtractionService",
    platforms: [.macOS(.v26)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "RTextExtractionService",
            targets: ["RTextExtractionService"]
        ),
    ],
    dependencies: [
        .package(path: "LocalPackages/RAudioTranscriptionService"),
        .package(path: "LocalPackages/RImageTextService"),
        .package(path: "LocalPackages/RPDFProcessingService"),
        .package(path: "LocalPackages/RVideoProcessingService"),
        .package(path: "LocalPackages/RDatabaseManager"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "RTextExtractionService",
            dependencies: [
                .product(name: "RAudioTranscriptionService", package: "RAudioTranscriptionService"),
                .product(name: "RImageTextService", package: "RImageTextService"),
                .product(name: "RPDFProcessingService", package: "RPDFProcessingService"),
                .product(name: "RVideoProcessingService", package: "RVideoProcessingService"),
                .product(name: "RDatabaseManager", package: "RDatabaseManager"),
            ]
        ),
    ]
)
