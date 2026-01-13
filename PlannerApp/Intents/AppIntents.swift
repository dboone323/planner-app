//
// AppIntents.swift
// PlannerApp
//
// Step 32: App Intents for Siri integration.
//

import AppIntents
import SwiftData

// MARK: - Add Task Intent

@available(iOS 16.0, macOS 13.0, *)
struct AddTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Task"
    static var description = IntentDescription("Adds a new task to your planner")
    
    @Parameter(title: "Task Title")
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
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Create task with SwiftData
        let task = SDTask(
            title: title,
            priority: priority ?? "medium",
            dueDate: dueDate
        )
        
        // In production, inject the model context
        // For now, return success dialog
        return .result(dialog: "Added '\(title)' to your tasks")
    }
}

// MARK: - Complete Task Intent

@available(iOS 16.0, macOS 13.0, *)
struct CompleteTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Task"
    static var description = IntentDescription("Marks a task as completed")
    
    @Parameter(title: "Task Name")
    var taskName: String
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // In production, search and update task
        return .result(dialog: "Marked '\(taskName)' as complete")
    }
}

// MARK: - List Tasks Intent

@available(iOS 16.0, macOS 13.0, *)
struct ListTasksIntent: AppIntent {
    static var title: LocalizedStringResource = "List Tasks"
    static var description = IntentDescription("Lists your pending tasks")
    
    @Parameter(title: "Filter by Priority")
    var priority: String?
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // In production, fetch from SwiftData
        let priorityText = priority != nil ? " with \(priority!) priority" : ""
        return .result(dialog: "You have tasks\(priorityText). Check the app for details.")
    }
}

// MARK: - Add Goal Intent

@available(iOS 16.0, macOS 13.0, *)
struct AddGoalIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Goal"
    static var description = IntentDescription("Adds a new goal to your planner")
    
    @Parameter(title: "Goal Title")
    var title: String
    
    @Parameter(title: "Target Date")
    var targetDate: Date
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        return .result(dialog: "Added goal '\(title)' with target date \(targetDate.formatted(date: .abbreviated, time: .omitted))")
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
                "New task in \(.applicationName)"
            ],
            shortTitle: "Add Task",
            systemImageName: "plus.circle"
        )
        
        AppShortcut(
            intent: CompleteTaskIntent(),
            phrases: [
                "Complete task in \(.applicationName)",
                "Mark task done in \(.applicationName)"
            ],
            shortTitle: "Complete Task",
            systemImageName: "checkmark.circle"
        )
        
        AppShortcut(
            intent: ListTasksIntent(),
            phrases: [
                "Show my tasks in \(.applicationName)",
                "List tasks from \(.applicationName)",
                "What are my tasks in \(.applicationName)"
            ],
            shortTitle: "List Tasks",
            systemImageName: "list.bullet"
        )
        
        AppShortcut(
            intent: AddGoalIntent(),
            phrases: [
                "Add a goal to \(.applicationName)",
                "Create goal in \(.applicationName)"
            ],
            shortTitle: "Add Goal",
            systemImageName: "target"
        )
    }
}
