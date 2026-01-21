import SwiftUI

struct TaskCardView: View {
    let task: PlannerTask
    let onToggle: (PlannerTask) -> Void
    let onEdit: (PlannerTask) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Priority Indicator Strip
            RoundedRectangle(cornerRadius: 2)
                .fill(priorityColor(task.priority))
                .frame(width: 4)
                .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 8) {
                // Header: Title and Due Date
                HStack(alignment: .top) {
                    Text(task.title)
                        .font(.headline)
                        .strikethrough(task.isCompleted)
                        .foregroundColor(task.isCompleted ? .secondary : .primary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()

                    if let dueDate = task.dueDate {
                        dueDateBadge(date: dueDate, isCompleted: task.isCompleted)
                    }
                }

                // Description (if present)
                if !task.description.isEmpty {
                    Text(task.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                // Footer: Priority and Actions
                HStack {
                    Label(task.priority.displayName, systemImage: "flag.fill")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(priorityColor(task.priority).opacity(0.1))
                        .foregroundColor(priorityColor(task.priority))
                        .cornerRadius(4)

                    Spacer()

                    Button(action: { onToggle(task) }, label: {
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundColor(task.isCompleted ? .green : .gray)
                    })
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(12)
        #if os(iOS)
            .background(Color(UIColor.secondarySystemGroupedBackground))
        #else
            .background(Color.gray.opacity(0.1))
        #endif
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
            .onTapGesture {
                onEdit(task)
            }
    }

    // MARK: - Helpers

    private func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .high: .red
        case .medium: .orange
        case .low: .blue
        }
    }

    private func dueDateBadge(date: Date, isCompleted: Bool) -> some View {
        let isOverdue = date < Date() && !isCompleted
        return Text(date.formatted(.relative(presentation: .named)))
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(isOverdue ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
            )
            .foregroundColor(isOverdue ? .red : .blue)
    }
}
