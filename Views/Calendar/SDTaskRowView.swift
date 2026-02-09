// PlannerApp/Views/Calendar/SDTaskRowView.swift
import SwiftData
import SwiftUI

/// SwiftData-compatible task row view for CalendarView.
public struct SDTaskRowView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let task: SDTask

    private var priorityColor: Color {
        switch self.task.priority {
        case "high": .red
        case "medium": .orange
        case "low": .green
        default: .gray
        }
    }

    private var priorityText: String {
        switch self.task.priority {
        case "high": "High"
        case "medium": "Medium"
        case "low": "Low"
        default: "None"
        }
    }

    private var isOverdue: Bool {
        guard let dueDate = task.dueDate else { return false }
        return !self.task.isCompleted && dueDate < Date()
    }

    public var body: some View {
        HStack(spacing: 12) {
            // Priority and status indicator
            VStack(alignment: .center, spacing: 2) {
                if self.task.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                } else if self.isOverdue {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.title3)
                } else {
                    Circle()
                        .fill(self.priorityColor)
                        .frame(width: 8, height: 8)
                }

                Text(self.priorityText)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(self.task.isCompleted ? .green : (self.isOverdue ? .red : self.priorityColor))
            }
            .frame(width: 50)

            // Task details
            VStack(alignment: .leading, spacing: 2) {
                Text(self.task.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(self.task.isCompleted
                        ? self.themeManager.currentTheme.secondaryTextColor
                        : self.themeManager.currentTheme.primaryTextColor)
                        .strikethrough(self.task.isCompleted)
                        .lineLimit(2)

                if !self.task.taskDescription.isEmpty {
                    Text(self.task.taskDescription)
                        .font(.caption)
                        .foregroundColor(self.themeManager.currentTheme.secondaryTextColor)
                        .lineLimit(1)
                }

                // Due date indicator
                if let dueDate = task.dueDate {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                            .foregroundColor(self.isOverdue ? .red : self.themeManager.currentTheme.secondaryTextColor)

                        Text("Due: \(self.dueDateFormatter.string(from: dueDate))")
                            .font(.caption2)
                            .foregroundColor(self.isOverdue ? .red : self.themeManager.currentTheme.secondaryTextColor)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private var dueDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
}
