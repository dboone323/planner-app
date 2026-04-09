import SwiftData
import SwiftUI

/// A list view component for displaying SDTask items.
/// Works with SwiftData's automatic observation.
public struct SDTaskListView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @FocusState.Binding var isInputFieldFocused: Bool

    let incompleteTasks: [SDTask]
    let completedTasks: [SDTask]
    let onDeleteIncomplete: (IndexSet) -> Void
    let onDeleteCompleted: (IndexSet) -> Void

    public var body: some View {
        List {
            // --- Incomplete Tasks Section ---
            Section {
                ForEach(self.incompleteTasks) { task in
                    SDTaskRow(taskItem: task)
                        .environmentObject(self.themeManager)
                        .listRowBackground(self.themeManager.currentTheme.secondaryBackgroundColor)
                }
                .onDelete(perform: self.onDeleteIncomplete)
            } header: {
                Text("To Do")
                    .font(self.themeManager.currentTheme.font(
                        forName: self.themeManager.currentTheme.primaryFontName, size: 14
                    ))
                    .foregroundColor(self.themeManager.currentTheme.secondaryTextColor)
            }

            // --- Completed Tasks Section ---
            if !self.completedTasks.isEmpty {
                Section {
                    ForEach(self.completedTasks) { task in
                        SDTaskRow(taskItem: task)
                            .environmentObject(self.themeManager)
                            .listRowBackground(self.themeManager.currentTheme.secondaryBackgroundColor)
                    }
                    .onDelete(perform: self.onDeleteCompleted)
                } header: {
                    Text("Completed")
                        .font(self.themeManager.currentTheme.font(
                            forName: self.themeManager.currentTheme.primaryFontName, size: 14
                        ))
                        .foregroundColor(self.themeManager.currentTheme.secondaryTextColor)
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.sidebar)
        #endif
        .scrollContentBackground(.hidden)
        .background(self.themeManager.currentTheme.primaryBackgroundColor)
        .onTapGesture {
            // Dismiss keyboard when tapping outside input field
            self.isInputFieldFocused = false
        }
    }
}
