// swift-tools-version: 6.2
// PlannerApp – Agent Tools
// Copyright © 2026 PlannerApp. All rights reserved.

import Foundation
import PackageDescription

private let localSharedKitPath = "../shared-kit"
private let sharedKitDependency: Package.Dependency = .package(path: localSharedKitPath)

let package = Package(
    name: "PlannerApp",
    platforms: [
        .iOS("26.0"),
        .macOS("26.0"),
    ],
    products: [
        .executable(
            name: "ScheduleAudit",
            targets: ["ScheduleAudit"]
        ),
        .library(
            name: "PlannerAppCore",
            targets: ["PlannerAppCore"]
        ),
        .library(
            name: "PlannerAgentCore",
            targets: ["PlannerAgentCore"]
        )
    ],
    dependencies: [
        sharedKitDependency
    ],
    targets: [
        // Application core framework
        .target(
            name: "PlannerAppCore",
            dependencies: [
                .product(name: "SharedKit", package: "shared-kit")
            ],
            path: "Sources/PlannerAppCore",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        // Core agent library – contains PlannerAgent conforming to BaseAgent
        .target(
            name: "PlannerAgentCore",
            dependencies: [
                "PlannerAppCore",
                .product(name: "SharedKit", package: "shared-kit")
            ],
            path: "Sources/PlannerAgentCore",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        // Audit executable
        .executableTarget(
            name: "ScheduleAudit",
            dependencies: ["PlannerAgentCore"],
            path: "Tools",
            exclude: ["ProjectScripts", "Automation"],
            sources: ["ScheduleAudit.swift"]
        ),
        .testTarget(
            name: "PlannerAgentCoreTests",
            dependencies: ["PlannerAgentCore"],
            path: "Tests/PlannerAgentCoreTests"
        ),
    ]
)