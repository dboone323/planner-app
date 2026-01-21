// PlannerApp/Views/Tasks/TaskManagerView.swift (Updated with iOS enhancements)
import Foundation
import SwiftData
import SwiftUI

#if os(iOS)
    import UIKit
#endif

// Type alias to distinguish our custom PlannerTask model from Swift's concurrency Task
// Use explicit reference to avoid ambiguity
// typealias PlannerTask = Task

public struct TaskManagerView: View {
    // Access shared ThemeManager and data arrays
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss // Add dismiss capability
    @Environment(\.modelContext) private var modelContext // SwiftData context

    // Use @Query for automatic data fetching from SwiftData
    @Query(sort: \SDTask.createdAt, order: .reverse) private var sdTasks: [SDTask]

    @State private var newTaskTitle = "" // State for the input field text
    @FocusState private var isInputFieldFocused: Bool // Tracks focus state of the input field

    // Computed properties to filter tasks into incomplete and completed lists
    private var incompleteTasks: [SDTask] {
        sdTasks.filter { !$0.isCompleted }
    }

    private var completedTasks: [SDTask] {
        sdTasks.filter(\.isCompleted)
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header with buttons for better macOS compatibility
            TaskManagerHeaderView()
                .environmentObject(themeManager)

            // Main container using VStack with no spacing for tight layout control
            VStack(spacing: 0) {
                // --- Input Area ---
                TaskInputView(
                    newTaskTitle: $newTaskTitle,
                    isInputFieldFocused: $isInputFieldFocused,
                    onAddTask: addTask
                )
                .environmentObject(themeManager)

                // --- Task List ---
                SDTaskListView(
                    isInputFieldFocused: $isInputFieldFocused,
                    incompleteTasks: incompleteTasks,
                    completedTasks: completedTasks,
                    onDeleteIncomplete: deleteTaskIncomplete,
                    onDeleteCompleted: deleteTaskCompleted
                )
                .environmentObject(themeManager)
            } // End main VStack
            // Ensure the primary background extends behind the navigation bar area if needed
            .background(themeManager.currentTheme.primaryBackgroundColor.ignoresSafeArea())
            .navigationTitle("Tasks")
            // Perform auto-deletion check when view appears
            .onAppear {
                performAutoDeletionIfNeeded() // Check and perform auto-deletion
            }
            .toolbar {
                // Custom Edit button for macOS list reordering/deletion mode
                ToolbarItem(placement: .navigation) {
                    Button("Edit", action: {
                        // Custom edit implementation for macOS
                    })
                    .accessibilityLabel("Button")
                }
                // Add a "Done" button to the keyboard toolbar
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer() // Push button to the right
                        Button("Done", action: { isInputFieldFocused = false }) // Dismiss keyboard on tap
                            .accessibilityLabel("Button")
                        // Uses theme accent color automatically
                    }
                }
            }
            // Apply theme accent color to navigation bar items (Edit, Done buttons)
            .accentColor(themeManager.currentTheme.primaryAccentColor)
        } // End main VStack
        #if os(macOS)
        .frame(minWidth: 500, minHeight: 400)
        #else
        .iOSPopupOptimizations()
        #endif
    }

    // --- Data Functions (SwiftData) ---

    // Adds a new task based on the input field text
    private func addTask() {
        let trimmedTitle = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return } // Don't add empty tasks

        // Create new SDTask and insert into context
        let newTask = SDTask(title: trimmedTitle)
        modelContext.insert(newTask)
        newTaskTitle = "" // Clear the input field
        isInputFieldFocused = false // Dismiss keyboard
    }

    // Handles deletion from the incomplete tasks section
    private func deleteTaskIncomplete(at offsets: IndexSet) {
        deleteTask(from: incompleteTasks, at: offsets)
    }

    // Handles deletion from the completed tasks section
    private func deleteTaskCompleted(at offsets: IndexSet) {
        deleteTask(from: completedTasks, at: offsets)
    }

    // Helper function to delete tasks based on offsets from a filtered array
    private func deleteTask(from sourceArray: [SDTask], at offsets: IndexSet) {
        for index in offsets {
            let task = sourceArray[index]
            modelContext.delete(task)
        }
    }

    // --- Auto Deletion Logic (SwiftData) ---
    // Checks settings and performs auto-deletion if enabled
    private func performAutoDeletionIfNeeded() {
        // Read settings directly using AppStorage within this function scope
        @AppStorage(AppSettingKeys.autoDeleteCompleted) var autoDeleteEnabled = false
        @AppStorage(AppSettingKeys.autoDeleteDays) var autoDeleteDays = 30

        // Only proceed if auto-delete is enabled
        guard autoDeleteEnabled else {
            print("Auto-deletion skipped (disabled).")
            return
        }

        // Calculate the cutoff date based on the setting
        guard let cutoffDate = Calendar.current.date(byAdding: .day, value: -autoDeleteDays, to: Date())
        else {
            print("Could not calculate cutoff date for auto-deletion.")
            return
        }

        // Find completed tasks older than cutoff date using modifiedAt
        let tasksToDelete = sdTasks.filter { task in
            guard task.isCompleted, let modifiedAt = task.modifiedAt else { return false }
            return modifiedAt < cutoffDate
        }

        // Delete matching tasks
        if !tasksToDelete.isEmpty {
            for task in tasksToDelete {
                modelContext.delete(task)
            }
            print("Auto-deleted \(tasksToDelete.count) tasks older than \(autoDeleteDays) days.")
        } else {
            print("No tasks found matching auto-deletion criteria.")
        }
    }
}
