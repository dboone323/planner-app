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
            Image(systemName: self.taskItem.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(
                    self.taskItem.isCompleted
                        ? self.themeManager.currentTheme.completedColor
                        : self.themeManager.currentTheme.secondaryTextColor
                )
                .font(.title3)
                .onTapGesture { self.toggleCompletion() }

            // Task title text
            Text(self.taskItem.title)
                .font(
                    self.themeManager.currentTheme.font(
                        forName: self.themeManager.currentTheme.primaryFontName, size: 16
                    )
                )
                .strikethrough(
                    self.taskItem.isCompleted, color: self.themeManager.currentTheme.secondaryTextColor
                )
                .foregroundColor(
                    self.taskItem.isCompleted
                        ? self.themeManager.currentTheme.secondaryTextColor
                        : self.themeManager.currentTheme.primaryTextColor
                )

            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture { self.toggleCompletion() }
    }

    /// Toggles the completion status of the task
    private func toggleCompletion() {
        #if os(iOS)
            if self.taskItem.isCompleted {
                HapticManager.lightImpact()
            } else {
                HapticManager.notificationSuccess()
            }
        #endif

        // SwiftData automatically tracks changes to @Model objects
        self.taskItem.isCompleted.toggle()
        self.taskItem.modifiedAt = Date()
        print("Toggled task '\(self.taskItem.title)' to \(self.taskItem.isCompleted)")
    }
}
