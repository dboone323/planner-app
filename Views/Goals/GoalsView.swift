// PlannerApp/Views/Goals/GoalsView.swift (Updated)
import SwiftUI

public struct GoalsView: View {
    // Access shared ThemeManager and data
    @EnvironmentObject var themeManager: ThemeManager
    @State private var goals: [Goal] = [] // Holds all goals
    @State private var showAddGoal = false // State to control presentation of AddGoal sheet

    // Read date/time settings if needed for display (e.g., formatter locale)
    @AppStorage(AppSettingKeys.use24HourTime) private var use24HourTime: Bool =
        false // Example, not used in formatter below

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                GoalsHeaderView(showAddGoal: $showAddGoal)
                    .environmentObject(themeManager)

                GoalsListView(
                    goals: goals,
                    onDelete: deleteGoal,
                    onProgressUpdate: updateGoalProgress,
                    onCompletionToggle: toggleGoalCompletion
                )
                .environmentObject(themeManager)
            }
            .sheet(isPresented: $showAddGoal) {
                // Present AddGoalView, passing binding and theme
                AddGoalView(goals: $goals)
                    .environmentObject(themeManager)
                    // Save goals when the sheet is dismissed
                    .onDisappear(perform: saveGoals)
            }
            // Load goals when the view appears
            .onAppear(perform: loadGoals)
        } // End NavigationStack
        // Use stack navigation style
    }

    // --- Data Functions ---

    // Updates the progress of a specific goal
    private func updateGoalProgress(goalId: UUID, progress: Double) {
        if let index = goals.firstIndex(where: { $0.id == goalId }) {
            goals[index].progress = progress
            goals[index].modifiedAt = Date()
            saveGoals()
        }
    }

    // Toggles the completion status of a specific goal
    private func toggleGoalCompletion(goalId: UUID) {
        if let index = goals.firstIndex(where: { $0.id == goalId }) {
            let wasCompleted = goals[index].isCompleted
            goals[index].isCompleted = !wasCompleted

            // If marking as completed, set progress to 100%
            if !wasCompleted {
                goals[index].progress = 1.0
            }
            // If unmarking as completed, set progress to 95% (allowing room for adjustment)
            else {
                goals[index].progress = 0.95
            }

            goals[index].modifiedAt = Date()
            saveGoals()
        }
    }

    // Deletes goals based on offsets from the sorted list displayed
    private func deleteGoal(at offsets: IndexSet) {
        // Get the sorted list as it's displayed in the ForEach loop
        let sortedGoals = goals.sorted(by: { $0.targetDate < $1.targetDate })
        // Map the offsets to the actual IDs of the goals to be deleted
        let idsToDelete = offsets.map { sortedGoals[$0].id }
        // Remove goals with matching IDs from the main `goals` array
        goals.removeAll { idsToDelete.contains($0.id) }
        saveGoals() // Persist changes
    }

    // Loads goals from the data manager
    private func loadGoals() {
        goals = GoalDataManager.shared.load()
        print("Goals loaded. Count: \(goals.count)")
    }

    // Saves the current state of the `goals` array to the data manager
    private func saveGoals() {
        GoalDataManager.shared.save(goals: goals)
        print("Goals saved.")
    }
}

// --- Preview Provider ---
public struct GoalsView_Previews: PreviewProvider {
    public static var previews: some View {
        GoalsView()
            // Provide ThemeManager for the preview
                .environmentObject(ThemeManager())
    }
}
