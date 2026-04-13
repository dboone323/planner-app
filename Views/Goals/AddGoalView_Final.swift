import PlannerApp
import SwiftUI
import PlannerAppCore

public struct AddGoalView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var goals: [PlannerGoal]

    @State private var title = ""
    @State private var description = ""
    @State private var targetDate = Date()

    var body: some View {
        NavigationView {
            Form {
                TextField("PlannerGoal Title", text: self.$title).accessibilityLabel("Text Field")
                    .accessibilityLabel("Text Field")
                TextField("Description", text: self.$description).accessibilityLabel("Text Field")
                    .accessibilityLabel("Text Field")
                DatePicker("Target Date", selection: self.$targetDate, displayedComponents: .date)
            }
            .navigationTitle("New PlannerGoal")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel").accessibilityLabel("Button").accessibilityLabel("Button") { self.dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save").accessibilityLabel("Button").accessibilityLabel("Button") {
                        let newGoal = PlannerGoal(title: title, taskDescription: description, targetDate: targetDate)
                        self.goals.append(newGoal)
                        WorkspaceManager.shared.save(goals: self.goals)
                        self.dismiss()
                    }
                    .disabled(self.title.isEmpty || self.description.isEmpty)
                }
            }
        }
    }
}
