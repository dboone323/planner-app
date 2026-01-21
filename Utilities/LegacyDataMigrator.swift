import Foundation
import SwiftData

/// Handles one-time migration of legacy UserDefaults data to SwiftData.
enum LegacyDataMigrator {
    /// UserDefaults key indicating migration is complete.
    private static let migrationCompleteKey = "swiftDataMigrationComplete_v1"

    /// Migrates legacy tasks and goals from UserDefaults to SwiftData.
    /// This should be called once at app startup.
    /// - Parameter context: The SwiftData ModelContext to insert data into.
    @MainActor
    static func migrateIfNeeded(context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: migrationCompleteKey) else {
            print("[LegacyDataMigrator] Migration already complete, skipping.")
            return
        }

        print("[LegacyDataMigrator] Starting legacy data migration...")

        var tasksCount = 0
        var goalsCount = 0

        // Migrate Tasks
        let legacyTasks = TaskDataManager.shared.load()
        for task in legacyTasks {
            let sdTask = SDTask(from: task)
            context.insert(sdTask)
            tasksCount += 1
        }

        // Migrate Goals
        let legacyGoals = GoalDataManager.shared.load()
        for goal in legacyGoals {
            let sdGoal = SDGoal(from: goal)
            context.insert(sdGoal)
            goalsCount += 1
        }

        // Save and mark complete
        do {
            try context.save()
            UserDefaults.standard.set(true, forKey: migrationCompleteKey)
            print("[LegacyDataMigrator] Migration complete: \(tasksCount) tasks, \(goalsCount) goals.")
        } catch {
            print("[LegacyDataMigrator] Migration failed: \(error.localizedDescription)")
        }
    }

    /// Resets the migration flag (for testing purposes).
    static func resetMigrationFlag() {
        UserDefaults.standard.removeObject(forKey: migrationCompleteKey)
    }
}
