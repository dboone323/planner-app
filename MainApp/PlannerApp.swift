// PlannerApp/MainApp/PlannerApp.swift (Updated)
import Foundation
import SwiftData
import SwiftUI

@main
public struct PlannerApp: App {
    // MARK: - SwiftData Configuration

    /// Shared model container for the entire app.
    /// Configures automatic CloudKit sync.
    /// Shared model container for the entire app.
    /// Configures automatic CloudKit sync and schema migration.
    var sharedModelContainer: ModelContainer = {
        let isTesting = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil ||
            ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_TESTS"] == "1" ||
            CommandLine.arguments.contains("-isTesting")

        print("DEBUG: PlannerApp starting. isTesting: \(isTesting)")

        do {
            let schema = Schema([SDTask.self, SDGoal.self])
            if isTesting {
                print("DEBUG: Creating in-memory ModelContainer for testing...")
                let configuration = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
                let container = try ModelContainer(for: schema, configurations: [configuration])
                print("DEBUG: In-memory ModelContainer created successfully.")
                return container
            } else {
                print("DEBUG: Creating persistent ModelContainer for production...")
                let configuration = ModelConfiguration(isStoredInMemoryOnly: false, cloudKitDatabase: .none)
                let container = try ModelContainer(for: schema, configurations: [configuration])
                print("DEBUG: Persistent ModelContainer created successfully.")
                return container
            }
        } catch {
            print("ERROR: Failed to create ModelContainer: \(error)")
            // Instead of crashing immediately, let's try to provide more context
            // In a real app, we might show a fallback UI, but here we still need to exit
            // if we can't function.
            fatalError("CRITICAL: Could not create ModelContainer. Error: \(error)")
        }
    }()

    /// Create and keep alive a single instance of ThemeManager for the entire app.
    /// @StateObject ensures it persists throughout the app's lifecycle.
    @StateObject private var themeManager = ThemeManager()

    /// State variable to hold the tag of the currently selected tab.
    /// This is needed to programmatically set the initial tab based on user settings.
    @State private var selectedTabTag: String

    /// Custom initializer to read the default view setting from UserDefaults
    /// *before* the main body view is created. This ensures the correct tab
    /// is selected right from the start.
    public init() {
        // Read the saved default view identifier from UserDefaults.
        let initialTab =
            UserDefaults.standard.string(forKey: AppSettingKeys.defaultView)
                // Use the Dashboard tag as a fallback if nothing is saved.
                ?? MainTabView.TabTags.dashboard
        // Initialize the @State variable with the value read from UserDefaults.
        // The underscore syntax is used here because we are initializing the State wrapper itself.
        _selectedTabTag = State(initialValue: initialTab)
        print("App starting. Initial tab set to: \(initialTab)") // Debugging log
    }

    public var body: some Scene {
        WindowGroup {
            // Apply the primary background color from the current theme to the entire window group.
            self.themeManager.currentTheme.primaryBackgroundColor
                .ignoresSafeArea()
                .overlay(
                    // Use enhanced navigation for better cross-platform UX
                    MainTabView(selectedTabTag: self.$selectedTabTag)
                )
                .environmentObject(self.themeManager)
                .plannerAccessibilityDefaults()
                .onAppear {
                    // Perform one-time legacy data migration
                    LegacyDataMigrator.migrateIfNeeded(
                        context: self.sharedModelContainer.mainContext
                    )
                    PlannerAppLifecycleCoordinator.configureOnLaunch()
                }
        }
        .modelContainer(self.sharedModelContainer)
        #if os(macOS)
            .windowStyle(.hiddenTitleBar)
            .windowToolbarStyle(.unified)
        #endif
    }
}
