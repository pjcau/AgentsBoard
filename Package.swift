// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "AgentsBoard",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "AgentsBoard", targets: ["AgentsBoard"]),
        .executable(name: "agentsctl", targets: ["AgentsBoardCLI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/migueldeicaza/SwiftTerm.git", from: "1.2.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0"),
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.24.0"),
    ],
    targets: [
        // Main app
        .executableTarget(
            name: "AgentsBoard",
            dependencies: [
                "AgentsBoardCore",
                "AgentsBoardUI",
            ],
            path: "Sources/App"
        ),

        // Core domain logic — zero UI dependencies
        .target(
            name: "AgentsBoardCore",
            dependencies: [
                "SwiftTerm",
                "Yams",
                .product(name: "GRDB", package: "GRDB.swift"),
            ],
            path: "Sources/Core",
            exclude: ["Rendering/Shaders.metal"]
        ),

        // UI layer — SwiftUI + AppKit
        .target(
            name: "AgentsBoardUI",
            dependencies: [
                "AgentsBoardCore",
            ],
            path: "Sources/UI"
        ),

        // CLI control tool
        .executableTarget(
            name: "AgentsBoardCLI",
            dependencies: [
                "AgentsBoardCore",
            ],
            path: "Sources/CLI"
        ),

        // Tests
        .testTarget(
            name: "AgentsBoardCoreTests",
            dependencies: ["AgentsBoardCore"],
            path: "Tests/CoreTests"
        ),
        .testTarget(
            name: "AgentsBoardUITests",
            dependencies: ["AgentsBoardUI"],
            path: "Tests/UITests"
        ),
    ]
)
