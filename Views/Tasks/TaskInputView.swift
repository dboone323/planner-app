// PlannerApp/Views/Tasks/TaskInputView.swift
import SwiftUI
import PlannerAppCore

public struct TaskInputView: View {
    @Binding var newTaskTitle: String
    var isInputFieldFocused: FocusState<Bool>.Binding
    var onAddTask: () -> Void

    public var body: some View {
        Text("PlannerTask Input View")
    }
}
