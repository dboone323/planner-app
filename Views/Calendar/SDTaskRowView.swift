// PlannerApp/Views/Calendar/SDTaskRowView.swift
import SwiftData
import SwiftUI

/// SwiftData-compatible task row view for CalendarView.
public struct SDTaskRowView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let task: SDTask

    private var priorityColor: Color {
        switch task.priority {
        case "high": .red
        case "medium": .orange
        case "low": .green
        default: .gray
        }
    }

    private var priorityText: String {
        switch task.priority {
        case "high": "High"
        case "medium": "Medium"
        case "low": "Low"
        default: "None"
        }
    }

    private var isOverdue: Bool {
        guard let dueDate = task.dueDate else { return false }
        return !task.isCompleted && dueDate < Date()
    }

    public var body: some View {
        HStack(spacing: 12) {
            // Priority and status indicator
            VStack(alignment: .center, spacing: 2) {
                if task.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                } else if isOverdue {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.title3)
                } else {
                    Circle()
                        .fill(priorityColor)
                        .frame(width: 8, height: 8)
                }

                Text(priorityText)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(task.isCompleted ? .green : (isOverdue ? .red : priorityColor))
            }
            .frame(width: 50)

            // Task details
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(task.isCompleted ?
                        themeManager.currentTheme.secondaryTextColor :
                        themeManager.currentTheme.primaryTextColor
                    )
                    .strikethrough(task.isCompleted)
                    .lineLimit(2)

                if !task.taskDescription.isEmpty {
                    Text(task.taskDescription)
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        .lineLimit(1)
                }

                // Due date indicator
                if let dueDate = task.dueDate {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                            .foregroundColor(isOverdue ? .red : themeManager.currentTheme.secondaryTextColor)

                        Text("Due: \(dueDateFormatter.string(from: dueDate))")
                            .font(.caption2)
                            .foregroundColor(isOverdue ? .red : themeManager.currentTheme.secondaryTextColor)
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
