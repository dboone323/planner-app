import SwiftUI

#if os(iOS)
    import UIKit
#endif

// Type alias to resolve conflict between Swift's built-in Task and our custom Task model
// typealias TaskModel = Task  // Removed - already defined in TaskManagerView

public struct TaskRow: View {
    // Access shared ThemeManager
    @EnvironmentObject var themeManager: ThemeManager
    // The specific task to display
    let taskItem: PlannerTask
    // Binding to the main tasks array to allow modification (toggling completion)
    @Binding var tasks: [PlannerTask]

    public var body: some View {
        HStack {
            // Checkmark icon (filled if completed, empty circle otherwise)
            Image(systemName: taskItem.isCompleted ? "checkmark.circle.fill" : "circle")
                // Apply theme colors based on completion status
                    .foregroundColor(
                        taskItem.isCompleted
                            ? themeManager.currentTheme.completedColor
                            : themeManager.currentTheme.secondaryTextColor
                    )
                    .font(.title3) // Make icon slightly larger
                    .onTapGesture { toggleCompletion() } // Toggle completion on icon tap

            // Task title text
            Text(taskItem.title)
                .font(
                    themeManager.currentTheme.font(
                        forName: themeManager.currentTheme.primaryFontName, size: 16
                    )
                )
                // Apply strikethrough effect if completed
                .strikethrough(
                    taskItem.isCompleted, color: themeManager.currentTheme.secondaryTextColor
                )
                // Apply theme text color based on completion status
                .foregroundColor(
                    taskItem.isCompleted
                        ? themeManager.currentTheme.secondaryTextColor
                        : themeManager.currentTheme.primaryTextColor
                )

            Spacer() // Push content to the left
        }
        .contentShape(Rectangle()) // Make the entire HStack tappable
        .onTapGesture { toggleCompletion() } // Toggle completion on row tap
        // Row background color is applied by the parent List section modifier
    }

    // Toggles the completion status of the task and saves changes
    private func toggleCompletion() {
        // Find the index of this task in the main array
        if let index = tasks.firstIndex(where: { $0.id == taskItem.id }) {
            #if os(iOS)
                // Add haptic feedback for task completion
                if tasks[index].isCompleted {
                    HapticManager.lightImpact()
                } else {
                    HapticManager.notificationSuccess()
                }
            #endif

            // Toggle the boolean state
            tasks[index].isCompleted.toggle()
            // ** IMPORTANT: Update completionDate if Task model supports it **
            // tasks[index].completionDate = tasks[index].isCompleted ? Date() : nil
            // Persist the change immediately
            TaskDataManager.shared.save(tasks: tasks)
            print("Toggled task '\(tasks[index].title)' to \(tasks[index].isCompleted)")
        }
    }
}

#Preview {
    let sampleTask = PlannerTask(
        title: "Sample Task",
        description: "This is a sample task",
        isCompleted: false,
        priority: .medium,
        dueDate: Date().addingTimeInterval(86400) // Tomorrow
    )

    TaskRow(taskItem: sampleTask, tasks: .constant([sampleTask]))
        .environmentObject(ThemeManager())
}
