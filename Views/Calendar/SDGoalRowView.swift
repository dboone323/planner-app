// PlannerApp/Views/Calendar/SDGoalRowView.swift
import SwiftData
import SwiftUI

/// SwiftData-compatible goal row view for CalendarView.
public struct SDGoalRowView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let goal: SDGoal

    private var priorityColor: Color {
        switch self.goal.priority {
        case "high": .red
        case "medium": .orange
        case "low": .green
        default: .gray
        }
    }

    private var priorityText: String {
        switch self.goal.priority {
        case "high": "High"
        case "medium": "Medium"
        case "low": "Low"
        default: "None"
        }
    }

    public var body: some View {
        HStack(spacing: 12) {
            // Priority indicator
            VStack(alignment: .center, spacing: 2) {
                Circle()
                    .fill(self.priorityColor)
                    .frame(width: 8, height: 8)

                Text(self.priorityText)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(self.priorityColor)
            }
            .frame(width: 50)

            // Goal details
            VStack(alignment: .leading, spacing: 4) {
                Text(self.goal.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(self.themeManager.currentTheme.primaryTextColor)
                    .lineLimit(2)

                if !self.goal.goalDescription.isEmpty {
                    Text(self.goal.goalDescription)
                        .font(.caption)
                        .foregroundColor(self.themeManager.currentTheme.secondaryTextColor)
                        .lineLimit(1)
                }

                // Progress bar
                if self.goal.progress > 0 {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("Progress")
                                .font(.caption2)
                                .foregroundColor(self.themeManager.currentTheme.secondaryTextColor)
                            Spacer()
                            Text("\(Int(self.goal.progress * 100))%")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                        }

                        ProgressView(value: self.goal.progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .green))
                            .scaleEffect(y: 0.8)
                    }
                }
            }

            Spacer()

            // Completion status
            if self.goal.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
            } else {
                Image(systemName: "target")
                    .foregroundColor(.green)
                    .font(.title3)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
