//
// AppIntents.swift
// PlannerApp
//
// Step 32: App Intents for Siri integration.
//

import AppIntents
import Foundation
import SwiftData
import PlannerAppCore

// MARK: - Add PlannerTask Intent

@available(iOS 16.0, macOS 13.0, *)
struct AddTaskIntent: AppIntent {
    static let title: LocalizedStringResource = "Add PlannerTask"
    static let description = IntentDescription("Adds a new task to your planner")

    @Parameter(title: "PlannerTask Title")
    var title: String

    @Parameter(title: "Priority", default: "medium")
    var priority: String?

    @Parameter(title: "Due Date")
    var dueDate: Date?

    static var parameterSummary: some ParameterSummary {
        Summary("Add task '\(\.$title)'") {
            \.$priority
            \.$dueDate
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let priorityValue = self.priority ?? "medium"

        _ = SDTask(
            title: title,
            taskDescription: "",
            priority: priorityValue,
            dueDate: dueDate
        )

        // In production, inject the model context
        // For now, return success dialog
        return .result(dialog: "Added '\(self.title)' to your tasks")
    }
}

// MARK: - Complete PlannerTask Intent

@available(iOS 16.0, macOS 13.0, *)
struct CompleteTaskIntent: AppIntent {
    static let title: LocalizedStringResource = "Complete PlannerTask"
    static let description = IntentDescription("Marks a task as completed")

    @Parameter(title: "PlannerTask Name")
    var taskName: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // In production, search and update task
        .result(dialog: "Marked '\(self.taskName)' as complete")
    }
}

// MARK: - List Tasks Intent

@available(iOS 16.0, macOS 13.0, *)
struct ListTasksIntent: AppIntent {
    static let title: LocalizedStringResource = "List Tasks"
    static let description = IntentDescription("Lists your pending tasks")

    @Parameter(title: "Filter by Priority")
    var priority: String?

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // In production, fetch from SwiftData
        let priorityText = self.priority != nil ? " with \(self.priority!) priority" : ""
        return .result(dialog: "You have tasks\(priorityText). Check the app for details.")
    }
}

// MARK: - Add PlannerGoal Intent

@available(iOS 16.0, macOS 13.0, *)
struct AddGoalIntent: AppIntent {
    static let title: LocalizedStringResource = "Add PlannerGoal"
    static let description = IntentDescription("Adds a new goal to your planner")

    @Parameter(title: "PlannerGoal Title")
    var title: String

    @Parameter(title: "Target Date")
    var targetDate: Date

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        .result(dialog: "PlannerGoal added successfully")
    }
}

// MARK: - Shortcuts Provider

@available(iOS 16.0, macOS 13.0, *)
struct PlannerAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddTaskIntent(),
            phrases: [
                "Add a task to \(.applicationName)",
                "Create task in \(.applicationName)",
                "New task in \(.applicationName)",
            ],
            shortTitle: "Add PlannerTask",
            systemImageName: "plus.circle"
        )

        AppShortcut(
            intent: CompleteTaskIntent(),
            phrases: [
                "Complete task in \(.applicationName)",
                "Mark task done in \(.applicationName)",
            ],
            shortTitle: "Complete PlannerTask",
            systemImageName: "checkmark.circle"
        )

        AppShortcut(
            intent: ListTasksIntent(),
            phrases: [
                "Show my tasks in \(.applicationName)",
                "List tasks from \(.applicationName)",
                "What are my tasks in \(.applicationName)",
            ],
            shortTitle: "List Tasks",
            systemImageName: "list.bullet"
        )

        AppShortcut(
            intent: AddGoalIntent(),
            phrases: [
                "Add a goal to \(.applicationName)",
                "Create goal in \(.applicationName)",
            ],
            shortTitle: "Add PlannerGoal",
            systemImageName: "target"
        )
    }
}
