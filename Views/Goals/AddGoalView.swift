import SwiftUI
import PlannerAppCore

public struct AddGoalView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var goals: [PlannerGoal]

    @State private var title = ""
    @State private var description = ""
    @State private var targetDate = Date()

    public var body: some View {
        NavigationView {
            Form {
                TextField("PlannerGoal Title", text: self.$title).accessibilityLabel("Text Field")
                TextField("Description", text: self.$description).accessibilityLabel("Text Field")
                DatePicker("Target Date", selection: self.$targetDate, displayedComponents: .date)
            }
            .navigationTitle("New PlannerGoal")
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", action: {
                    self.dismiss()
                })
                .accessibilityLabel("Button")
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: {
                    let newGoal = PlannerGoal(
                        title: title, goalDescription: description, targetDate: targetDate
                    )
                    self.goals.append(newGoal)
                    WorkspaceManager.shared.save(goals: self.goals)
                    self.dismiss()
                })
                .accessibilityLabel("Button")
                .disabled(self.title.isEmpty || self.description.isEmpty)
            }
        }
    }
}
