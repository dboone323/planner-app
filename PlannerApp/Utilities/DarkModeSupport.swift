//
// DarkModeSupport.swift
// PlannerApp
//
// Step 23: Enhanced dark mode support for all views.
//

import SwiftUI

/// App-wide color scheme manager.
public final class AppearanceManager: ObservableObject {
    public static let shared = AppearanceManager()

    @Published public var colorScheme: ColorScheme?
    @Published public var useSystemAppearance: Bool = true

    private init() {
        self.loadPreferences()
    }

    public func setDarkMode() {
        self.colorScheme = .dark
        self.useSystemAppearance = false
        self.savePreferences()
    }

    public func setLightMode() {
        self.colorScheme = .light
        self.useSystemAppearance = false
        self.savePreferences()
    }

    public func setSystemMode() {
        self.colorScheme = nil
        self.useSystemAppearance = true
        self.savePreferences()
    }

    private func loadPreferences() {
        self.useSystemAppearance = UserDefaults.standard.bool(forKey: "useSystemAppearance")
        if !self.useSystemAppearance {
            let isDark = UserDefaults.standard.bool(forKey: "isDarkMode")
            self.colorScheme = isDark ? .dark : .light
        }
    }

    private func savePreferences() {
        UserDefaults.standard.set(self.useSystemAppearance, forKey: "useSystemAppearance")
        UserDefaults.standard.set(self.colorScheme == .dark, forKey: "isDarkMode")
    }
}

/// Semantic colors that adapt to dark mode.
public enum AdaptiveColors {
    // Primary colors
    public static let primary = Color.accentColor
    public static let secondary = Color.secondary

    // Background colors
    public static let background = Color(uiColor: .systemBackground)
    public static let secondaryBackground = Color(uiColor: .secondarySystemBackground)
    public static let tertiaryBackground = Color(uiColor: .tertiarySystemBackground)

    // Text colors
    public static let primaryText = Color(uiColor: .label)
    public static let secondaryText = Color(uiColor: .secondaryLabel)
    public static let tertiaryText = Color(uiColor: .tertiaryLabel)

    /// Separator
    public static let separator = Color(uiColor: .separator)

    /// Grouped table
    public static let groupedBackground = Color(uiColor: .systemGroupedBackground)

    // Status colors (consistent in both modes)
    public static let success = Color.green
    public static let warning = Color.orange
    public static let error = Color.red
    public static let info = Color.blue

    /// Priority colors
    public static func priorityColor(for priority: String) -> Color {
        switch priority.lowercased() {
        case "high": .red
        case "medium": .orange
        case "low": .green
        default: .gray
        }
    }
}

// Platform-independent UIColor wrapper
#if os(iOS)
    import UIKit

    typealias PlatformColor = UIColor
#else
    import AppKit

    typealias PlatformColor = NSColor

    extension Color {
        init(uiColor: NSColor) {
            self.init(nsColor: uiColor)
        }
    }

    extension NSColor {
        static var label: NSColor { .labelColor }
        static var secondaryLabel: NSColor { .secondaryLabelColor }
        static var tertiaryLabel: NSColor { .tertiaryLabelColor }
        static var systemBackground: NSColor { .windowBackgroundColor }
        static var secondarySystemBackground: NSColor { .controlBackgroundColor }
        static var tertiarySystemBackground: NSColor { .controlBackgroundColor }
        static var systemGroupedBackground: NSColor { .windowBackgroundColor }
        static var separator: NSColor { .separatorColor }
    }
#endif

/// View modifier for applying dark mode.
struct DarkModeViewModifier: ViewModifier {
    @ObservedObject var manager = AppearanceManager.shared

    func body(content: Content) -> some View {
        content
            .preferredColorScheme(self.manager.colorScheme)
    }
}

extension View {
    func withDarkModeSupport() -> some View {
        modifier(DarkModeViewModifier())
    }
}
