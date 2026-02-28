// swift-tools-version: 6.2
// PlannerApp – Agent Tools
// Copyright © 2026 PlannerApp. All rights reserved.

import Foundation
import PackageDescription

private let localSharedKitPath = "../shared-kit"
private let sharedKitDependency: Package.Dependency = FileManager.default.fileExists(atPath: localSharedKitPath)
    ? .package(path: localSharedKitPath)
    : .package(url: "https://github.com/dboone323/shared-kit.git", branch: "main")

let package = Package(
    name: "PlannerApp",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .executable(
            name: "ScheduleAudit",
            targets: ["ScheduleAudit"]
        )
    ],
    dependencies: [
        sharedKitDependency,
    ],
    targets: [
        // Core agent library – contains PlannerAgent conforming to BaseAgent
        .target(
            name: "PlannerAgentCore",
            dependencies: [
                .product(name: "SharedKit", package: "shared-kit"),
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
    ]
)
