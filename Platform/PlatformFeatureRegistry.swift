//
//  PlatformFeatureRegistry.swift
//  PlannerApp
//
//  Platform feature flag management
//

import Foundation

public enum SupportedPlatform: String, CaseIterable, Sendable {
    case iOS
    case macOS
    case watchOS
    case visionOS
}

public struct PlatformFeatureFlags: Sendable, Codable, Equatable {
    public var widgetsEnabled: Bool
    public var siriShortcutsEnabled: Bool
    public var coreMLEnabled: Bool
    public var arkitEnabled: Bool
    public var cloudKitSharingEnabled: Bool
    public var healthKitEnabled: Bool
    public var homeKitEnabled: Bool
    public var callKitEnabled: Bool
    public var carPlayEnabled: Bool

    public init(
        widgetsEnabled: Bool = false,
        siriShortcutsEnabled: Bool = false,
        coreMLEnabled: Bool = false,
        arkitEnabled: Bool = false,
        cloudKitSharingEnabled: Bool = false,
        healthKitEnabled: Bool = false,
        homeKitEnabled: Bool = false,
        callKitEnabled: Bool = false,
        carPlayEnabled: Bool = false
    ) {
        self.widgetsEnabled = widgetsEnabled
        self.siriShortcutsEnabled = siriShortcutsEnabled
        self.coreMLEnabled = coreMLEnabled
        self.arkitEnabled = arkitEnabled
        self.cloudKitSharingEnabled = cloudKitSharingEnabled
        self.healthKitEnabled = healthKitEnabled
        self.homeKitEnabled = homeKitEnabled
        self.callKitEnabled = callKitEnabled
        self.carPlayEnabled = carPlayEnabled
    }
}

public actor PlatformFeatureRegistry {
    public static let shared = PlatformFeatureRegistry()

    private var registry: [SupportedPlatform: PlatformFeatureFlags] = [:]

    private init() {
        // Set default feature flags based on platform
        #if os(iOS)
            let defaultFlags = PlatformFeatureFlags(
                widgetsEnabled: true,
                siriShortcutsEnabled: true,
                coreMLEnabled: false, // Enable when CoreML models are available
                arkitEnabled: false, // Enable when AR features are implemented
                cloudKitSharingEnabled: true,
                healthKitEnabled: true, // Enable HealthKit by default on iOS
                homeKitEnabled: false, // Enable when HomeKit features are implemented
                callKitEnabled: false, // Enable when CallKit features are implemented
                carPlayEnabled: false // Enable when CarPlay is implemented
            )
            registry[.iOS] = defaultFlags
        #elseif os(macOS)
            let defaultFlags = PlatformFeatureFlags(
                widgetsEnabled: false, // macOS doesn't have widgets like iOS
                siriShortcutsEnabled: false, // macOS has different shortcut system
                coreMLEnabled: true, // macOS can run CoreML models
                arkitEnabled: false, // macOS has limited AR support
                cloudKitSharingEnabled: true,
                healthKitEnabled: false, // macOS doesn't have HealthKit
                homeKitEnabled: true, // macOS supports HomeKit
                callKitEnabled: false, // macOS has different calling APIs
                carPlayEnabled: false // CarPlay is iOS-only
            )
            registry[.macOS] = defaultFlags
        #endif
    }

    public func setFlags(_ flags: PlatformFeatureFlags, for platform: SupportedPlatform) {
        registry[platform] = flags
    }

    public func flags(for platform: SupportedPlatform) -> PlatformFeatureFlags {
        registry[platform] ?? PlatformFeatureFlags()
    }

    public func reset() {
        registry.removeAll()
    }
}