// PlannerApp/Components/Goals/GoalsHeaderView.swift
import Foundation
import SwiftUI

public struct GoalsHeaderView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var showAddGoal: Bool

    public var body: some View {
        HStack {
            Spacer()
            Text("Goals")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.currentTheme.primaryTextColor)
            Spacer()
        }
        .padding()
        .background(themeManager.currentTheme.secondaryBackgroundColor)
        .navigationTitle("Goals")
        .toolbar {
            // Button to show the AddGoalView sheet
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddGoal.toggle()
                } label: {
                    Image(systemName: "plus")
                }
            }
            // Custom Edit button for macOS
            ToolbarItem(placement: .navigation) {
                Button("Edit", action: {
                    // Custom edit implementation for macOS
                })
                .accessibilityLabel("Button")
            }
        }
        .accentColor(themeManager.currentTheme.primaryAccentColor)
    }
}
