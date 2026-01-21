// PlannerApp/Components/Tasks/TaskListView.swift
import Foundation
import SwiftUI

#if os(iOS)
    import UIKit
#endif

public struct TaskListView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @FocusState.Binding var isInputFieldFocused: Bool
    let incompleteTasks: [PlannerTask]
    let completedTasks: [PlannerTask]
    @Binding var tasks: [PlannerTask]
    let onDeleteIncomplete: (IndexSet) -> Void
    let onDeleteCompleted: (IndexSet) -> Void

    public var body: some View {
        List {
            // --- Incomplete Tasks Section ---
            Section("To Do (\(incompleteTasks.count))") {
                if incompleteTasks.isEmpty {
                    // Message shown when no incomplete tasks exist
                    Text("No tasks yet!")
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        .font(
                            themeManager.currentTheme.font(
                                forName: themeManager.currentTheme.secondaryFontName,
                                size: 15
                            )
                        )
                } else {
                    // Iterate over incomplete tasks and display using TaskRow
                    ForEach(incompleteTasks) { task in
                        TaskRow(taskItem: task, tasks: $tasks) // Pass task and binding to tasks array
                            .environmentObject(themeManager) // Ensure TaskRow can access theme
                    }
                    .onDelete(perform: onDeleteIncomplete) // Enable swipe-to-delete
                }
            }
            .listRowBackground(themeManager.currentTheme.secondaryBackgroundColor) // Theme row background
            .foregroundColor(themeManager.currentTheme.primaryTextColor) // Theme row text color
            .headerProminence(.increased) // Style section header

            // --- Completed Tasks Section ---
            Section("Completed (\(completedTasks.count))") {
                if completedTasks.isEmpty {
                    // Message shown when no completed tasks exist
                    Text("No completed tasks.")
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        .font(
                            themeManager.currentTheme.font(
                                forName: themeManager.currentTheme.secondaryFontName,
                                size: 15
                            )
                        )
                } else {
                    // Iterate over completed tasks
                    ForEach(completedTasks) { task in
                        TaskRow(taskItem: task, tasks: $tasks)
                            .environmentObject(themeManager)
                    }
                    .onDelete(perform: onDeleteCompleted) // Enable swipe-to-delete
                }
            }
            .listRowBackground(themeManager.currentTheme.secondaryBackgroundColor)
            .foregroundColor(themeManager.currentTheme.primaryTextColor)
            .headerProminence(.increased)
        }
        // Apply theme background color to the List view itself
        .background(themeManager.currentTheme.primaryBackgroundColor)
        // Hide the default List background style (e.g., plain/grouped)
        .scrollContentBackground(.hidden)
        // Add tap gesture to the List to dismiss keyboard when tapping outside the text field
        .onTapGesture {
            isInputFieldFocused = false
            #if os(iOS)
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder), to: nil, from: nil,
                    for: nil
                )
            #endif
        }
        #if os(iOS)
        .iOSKeyboardDismiss()
        #endif
    }
}
