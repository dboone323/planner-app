import Foundation
import Security
import SwiftUI

#if os(iOS)
import UIKit
import UserNotifications
#endif

@MainActor
enum PlannerAppLifecycleCoordinator {
    static func configureOnLaunch() {
        UserDefaults.standard.register(defaults: [
            AppSettingKeys.notificationsEnabled: true,
            AppSettingKeys.autoSyncEnabled: true,
            AppSettingKeys.use24HourTime: false,
        ])

        if PlannerSecureStore.bool(forKey: "planner.biometric_enabled") == nil {
            _ = PlannerSecureStore.set(false, forKey: "planner.biometric_enabled")
        }

        _ = NetworkSecurityPolicy.makeSecureSession()

        #if os(iOS)
        Task {
            _ = await requestNotificationAuthorizationIfNeeded()
        }
        UIApplication.shared.registerForRemoteNotifications()
        #endif
    }

    #if os(iOS)
    private static func requestNotificationAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let currentSettings = await center.notificationSettings()

        if currentSettings.authorizationStatus == .authorized {
            return true
        }

        do {
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }
    #endif
}

enum PlannerSecureStore {
    static func set(_ value: Bool, forKey key: String) -> Bool {
        let data = Data([value ? 1 : 0])
        return set(data, forKey: key)
    }

    static func bool(forKey key: String) -> Bool? {
        guard let data = data(forKey: key) else { return nil }
        return data.first == 1
    }

    static func set(_ data: Data, forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "PlannerApp",
            kSecAttrAccount as String: key,
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
        ]

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        if status == errSecSuccess {
            return SecItemUpdate(query as CFDictionary, attributes as CFDictionary) == errSecSuccess
        }

        var addQuery = query
        addQuery.merge(attributes) { _, new in new }
        return SecItemAdd(addQuery as CFDictionary, nil) == errSecSuccess
    }

    private static func data(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "PlannerApp",
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }
}

struct PlannerAccessibilityDefaultsModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .dynamicTypeSize(.xSmall ... .accessibility5)
            .accessibilityElement(children: .contain)
    }
}

extension View {
    func plannerAccessibilityDefaults() -> some View {
        modifier(PlannerAccessibilityDefaultsModifier())
    }
}
