// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "apfel-tag",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "ApfelTagCore", targets: ["ApfelTagCore"]),
        .executable(name: "apfel-tag", targets: ["apfel-tag"]),
    ],
    targets: [
        // Pure-logic library - no FoundationModels, fully unit-testable.
        .target(
            name: "ApfelTagCore",
            dependencies: [],
            path: "Sources/Core"
        ),
        // Main executable - FoundationModels content-tagging integration.
        .executableTarget(
            name: "apfel-tag",
            dependencies: ["ApfelTagCore"],
            path: "Sources",
            exclude: ["Core"],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "./Info.plist",
                ])
            ]
        ),
        // Pure-Swift test runner (no XCTest) - `swift run apfel-tag-tests`.
        .executableTarget(
            name: "apfel-tag-tests",
            dependencies: ["ApfelTagCore"],
            path: "Tests/apfel-tag-tests"
        ),
    ]
)
