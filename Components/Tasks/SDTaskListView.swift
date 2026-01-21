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
                ForEach(incompleteTasks) { task in
                    SDTaskRow(taskItem: task)
                        .environmentObject(themeManager)
                        .listRowBackground(themeManager.currentTheme.secondaryBackgroundColor)
                }
                .onDelete(perform: onDeleteIncomplete)
            } header: {
                Text("To Do")
                    .font(themeManager.currentTheme.font(
                        forName: themeManager.currentTheme.primaryFontName, size: 14
                    ))
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            }

            // --- Completed Tasks Section ---
            if !completedTasks.isEmpty {
                Section {
                    ForEach(completedTasks) { task in
                        SDTaskRow(taskItem: task)
                            .environmentObject(themeManager)
                            .listRowBackground(themeManager.currentTheme.secondaryBackgroundColor)
                    }
                    .onDelete(perform: onDeleteCompleted)
                } header: {
                    Text("Completed")
                        .font(themeManager.currentTheme.font(
                            forName: themeManager.currentTheme.primaryFontName, size: 14
                        ))
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.sidebar)
        #endif
        .scrollContentBackground(.hidden)
        .background(themeManager.currentTheme.primaryBackgroundColor)
        .onTapGesture {
            // Dismiss keyboard when tapping outside input field
            isInputFieldFocused = false
        }
    }
}
