// PlannerApp/Components/Goals/GoalsListView.swift
import Foundation
import SwiftUI

public struct GoalsListView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let goals: [Goal]
    let onDelete: (IndexSet) -> Void
    let onProgressUpdate: (UUID, Double) -> Void
    let onCompletionToggle: (UUID) -> Void

    public var body: some View {
        List {
            if goals.isEmpty {
                GoalsEmptyStateView()
                    .environmentObject(themeManager)
            } else {
                // Iterate over goals sorted by target date
                ForEach(goals.sorted(by: { $0.targetDate < $1.targetDate })) { goal in
                    GoalItemView(
                        goal: goal,
                        onProgressUpdate: onProgressUpdate,
                        onCompletionToggle: onCompletionToggle
                    )
                    .environmentObject(themeManager)
                }
                .onDelete(perform: onDelete) // Enable swipe-to-delete
                // Apply theme background to all rows in the list
                .listRowBackground(themeManager.currentTheme.secondaryBackgroundColor)
            }
        }
        .background(themeManager.currentTheme.primaryBackgroundColor) // Apply theme background to List
        .scrollContentBackground(.hidden) // Hide default List background style
    }
}
