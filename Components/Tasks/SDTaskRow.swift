import SwiftData
import SwiftUI

#if os(iOS)
    import UIKit
#endif

/// A row component for displaying an SDTask in a list.
/// Uses SwiftData's modelContext for updates.
public struct SDTaskRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.modelContext) private var modelContext

    /// The task to display
    @Bindable var taskItem: SDTask

    public var body: some View {
        HStack {
            // Checkmark icon (filled if completed, empty circle otherwise)
            Image(systemName: taskItem.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(
                    taskItem.isCompleted
                        ? themeManager.currentTheme.completedColor
                        : themeManager.currentTheme.secondaryTextColor
                )
                .font(.title3)
                .onTapGesture { toggleCompletion() }

            // Task title text
            Text(taskItem.title)
                .font(
                    themeManager.currentTheme.font(
                        forName: themeManager.currentTheme.primaryFontName, size: 16
                    )
                )
                .strikethrough(
                    taskItem.isCompleted, color: themeManager.currentTheme.secondaryTextColor
                )
                .foregroundColor(
                    taskItem.isCompleted
                        ? themeManager.currentTheme.secondaryTextColor
                        : themeManager.currentTheme.primaryTextColor
                )

            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture { toggleCompletion() }
    }

    /// Toggles the completion status of the task
    private func toggleCompletion() {
        #if os(iOS)
            if taskItem.isCompleted {
                HapticManager.lightImpact()
            } else {
                HapticManager.notificationSuccess()
            }
        #endif

        // SwiftData automatically tracks changes to @Model objects
        taskItem.isCompleted.toggle()
        taskItem.modifiedAt = Date()
        print("Toggled task '\(taskItem.title)' to \(taskItem.isCompleted)")
    }
}
