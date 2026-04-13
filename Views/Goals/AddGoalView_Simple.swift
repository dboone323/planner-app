import PlannerApp
import SwiftUI
import PlannerAppCore

public struct AddGoalView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var goals: [PlannerGoal]

    @State private var title = ""
    @State private var description = ""
    @State private var targetDate = Date()

    private var isFormValid: Bool {
        !self.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !self.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationView {
            Form {
                Section("PlannerGoal Details") {
                    TextField("PlannerGoal Title", text: self.$title).accessibilityLabel("Text Field")
                        .accessibilityLabel("Text Field")

                    TextField("Description", text: self.$description, axis: .vertical).accessibilityLabel("Text Field")
                        .accessibilityLabel("Text Field")
                        .lineLimit(3...6)

                    DatePicker("Target Date", selection: self.$targetDate, displayedComponents: .date)
                }
            }
            .navigationTitle("New PlannerGoal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel").accessibilityLabel("Button").accessibilityLabel("Button") {
                        self.dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save").accessibilityLabel("Button").accessibilityLabel("Button") {
                        self.saveGoal()
                        self.dismiss()
                    }
                    .disabled(!self.isFormValid)
                }
            }
        }
    }

    private func saveGoal() {
        let newGoal = PlannerGoal(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            taskDescription: self.description.trimmingCharacters(in: .whitespacesAndNewlines),
            targetDate: self.targetDate
        )
        self.goals.append(newGoal)
        WorkspaceManager.shared.save(goals: self.goals)
    }
}

public struct AddGoalView_Previews: PreviewProvider {
    static var previews: some View {
        AddGoalView(goals: Binding.constant([]))
    }
}
