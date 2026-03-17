// swift-tools-version: 6.0

import PackageDescription

// MARK: - Platform-conditional dependencies

#if os(macOS)
let swiftTermDependency: [Package.Dependency] = [
    .package(url: "https://github.com/migueldeicaza/SwiftTerm.git", from: "1.2.0"),
]
let swiftTermTarget: [Target.Dependency] = ["SwiftTerm"]
#else
let swiftTermDependency: [Package.Dependency] = []
let swiftTermTarget: [Target.Dependency] = []
#endif

// Shared Swift settings: disable strict concurrency for existing code not yet migrated
let sharedSwiftSettings: [SwiftSetting] = [
    .swiftLanguageMode(.v5),
]

// macOS-only targets (app, UI, UI tests)
#if os(macOS)
let macOSTargets: [Target] = [
    .executableTarget(
        name: "AgentsBoard",
        dependencies: [
            "AgentsBoardCore",
            "AgentsBoardUI",
        ],
        path: "Sources/App",
        resources: [
            .copy("Resources/AppIcon.icns"),
        ],
        swiftSettings: sharedSwiftSettings
    ),
    .target(
        name: "AgentsBoardUI",
        dependencies: [
            "AgentsBoardCore",
        ] + swiftTermTarget,
        path: "Sources/UI",
        resources: [
            .process("Localization"),
        ],
        swiftSettings: sharedSwiftSettings
    ),
    .testTarget(
        name: "AgentsBoardUITests",
        dependencies: ["AgentsBoardUI"],
        path: "Tests/UITests",
        swiftSettings: sharedSwiftSettings
    ),
    .executableTarget(
        name: "AgentsBoardCLI",
        dependencies: [
            "AgentsBoardCore",
        ],
        path: "Sources/CLI",
        swiftSettings: sharedSwiftSettings
    ),
]
let macOSProducts: [Product] = [
    .executable(name: "AgentsBoard", targets: ["AgentsBoard"]),
    .executable(name: "agentsctl", targets: ["AgentsBoardCLI"]),
]
#else
let macOSTargets: [Target] = []
let macOSProducts: [Product] = []
#endif

let package = Package(
    name: "AgentsBoard",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14)
    ],
    products: macOSProducts + [
        .executable(name: "AgentsBoardServer", targets: ["AgentsBoardServer"]),
        .library(name: "AgentsBoardCore", targets: ["AgentsBoardCore"]),
    ],
    dependencies: swiftTermDependency + [
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0"),
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.24.0"),
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.0"),
        .package(url: "https://github.com/hummingbird-project/hummingbird-websocket.git", from: "2.0.0"),
    ],
    targets: macOSTargets + [
        // Core domain logic — zero UI dependencies, cross-platform
        .target(
            name: "AgentsBoardCore",
            dependencies: swiftTermTarget + [
                "Yams",
                .product(name: "GRDB", package: "GRDB.swift"),
            ],
            path: "Sources/Core",
            exclude: ["Rendering/Shaders.metal"],
            swiftSettings: sharedSwiftSettings
        ),

        // HTTP + WebSocket API server (cross-platform)
        .executableTarget(
            name: "AgentsBoardServer",
            dependencies: [
                "AgentsBoardCore",
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "HummingbirdWebSocket", package: "hummingbird-websocket"),
            ],
            path: "Sources/Server",
            swiftSettings: sharedSwiftSettings
        ),

        // Tests
        .testTarget(
            name: "AgentsBoardCoreTests",
            dependencies: ["AgentsBoardCore"],
            path: "Tests/CoreTests",
            swiftSettings: sharedSwiftSettings
        ),
        .testTarget(
            name: "AgentsBoardServerTests",
            dependencies: [
                "AgentsBoardCore",
            ],
            path: "Tests/ServerTests",
            swiftSettings: sharedSwiftSettings
        ),
    ]
)
