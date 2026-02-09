import SwiftUI

struct TaskCardView: View {
    let task: PlannerTask
    let onToggle: (PlannerTask) -> Void
    let onEdit: (PlannerTask) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Priority Indicator Strip
            RoundedRectangle(cornerRadius: 2)
                .fill(self.priorityColor(self.task.priority))
                .frame(width: 4)
                .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 8) {
                // Header: Title and Due Date
                HStack(alignment: .top) {
                    Text(self.task.title)
                        .font(.headline)
                        .strikethrough(self.task.isCompleted)
                        .foregroundColor(self.task.isCompleted ? .secondary : .primary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()

                    if let dueDate = task.dueDate {
                        self.dueDateBadge(date: dueDate, isCompleted: self.task.isCompleted)
                    }
                }

                // Description (if present)
                if !self.task.description.isEmpty {
                    Text(self.task.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                // Footer: Priority and Actions
                HStack {
                    Label(self.task.priority.displayName, systemImage: "flag.fill")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(self.priorityColor(self.task.priority).opacity(0.1))
                        .foregroundColor(self.priorityColor(self.task.priority))
                        .cornerRadius(4)

                    Spacer()

                    Button(action: { self.onToggle(self.task) }, label: {
                        Image(systemName: self.task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundColor(self.task.isCompleted ? .green : .gray)
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
                self.onEdit(self.task)
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
