// swift-tools-version: 6.0
// PlannerApp - Personal Planning and Productivity App
// Copyright © 2025 PlannerApp. All rights reserved.

import PackageDescription

let package = Package(
    name: "PlannerApp",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "PlannerApp",
            targets: ["PlannerAppCore"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "PlannerAppCore",
            dependencies: [],
            path: "PlannerApp",
            exclude: ["Info.plist", "Preview Content"],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "PlannerAppTests",
            dependencies: ["PlannerAppCore"],
            path: "PlannerAppTests"
        )
    ]
)
