import SwiftUI

/// View for managing and displaying projects
struct ProjectsView: View {
    @State private var projects: [PlannerProject] = []
    @State private var showingAddProject = false
    @State private var selectedStatus: PlannerProject.ProjectStatus = .active

    private let projectDataManager = ProjectDataManager.shared
    private let taskDataManager = TaskDataManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                #if os(iOS)
                    Color(uiColor: .systemGroupedBackground)
                        .ignoresSafeArea()
                #else
                    Color.gray.opacity(0.1)
                        .ignoresSafeArea()
                #endif

                if projects.isEmpty {
                    emptyStateView
                } else {
                    VStack(spacing: 0) {
                        // Status filter picker
                        Picker("Status", selection: $selectedStatus) {
                            ForEach(PlannerProject.ProjectStatus.allCases, id: \.self) { status in
                                Text(status.displayName)
                                    .tag(status)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .padding(.top)

                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(filteredProjects) { project in
                                    ProjectCardView(
                                        project: project,
                                        tasks: getTasksForProject(project),
                                        onEdit: { editProject(project) },
                                        onDelete: { deleteProject(project) }
                                    )
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Projects")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(
                        action: { showingAddProject = true },
                        label: {
                            Label("Add Project", systemImage: "plus")
                        })
                }
            }
            .sheet(isPresented: $showingAddProject) {
                AddProjectView(onSave: { project in
                    addProject(project)
                    showingAddProject = false
                })
            }
            .onAppear {
                loadProjects()
            }
            .onChange(of: selectedStatus) { _, _ in
                // Projects will be filtered automatically
            }
        }
    }

    private var filteredProjects: [PlannerProject] {
        if selectedStatus == .active {
            projects.filter { $0.status == .active }
        } else {
            projects.filter { $0.status == selectedStatus }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))
            Text("No projects yet!")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            Text("Create your first project to organize your tasks")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Create Project") {
                showingAddProject = true
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
        }
        .padding()
    }

    private func loadProjects() {
        projects = projectDataManager.load().sorted {
            // Sort: Active first, then by creation date
            if $0.status != $1.status {
                return $0.status == .active && $1.status != .active
            }
            return $0.createdAt > $1.createdAt
        }
    }

    private func addProject(_ project: PlannerProject) {
        projectDataManager.add(project)
        loadProjects()
    }

    private func editProject(_ project: PlannerProject) {
        // TODO: Implement edit functionality
        print("Edit project: \(project.name)")
    }

    private func deleteProject(_ project: PlannerProject) {
        projectDataManager.delete(project)
        loadProjects()
    }

    private func getTasksForProject(_ project: PlannerProject) -> [PlannerTask] {
        let allTasks = taskDataManager.load()
        return allTasks.filter { $0.projectId == project.id }
    }
}

/// Card view for displaying project information
struct ProjectCardView: View {
    let project: PlannerProject
    let tasks: [PlannerTask]
    let onEdit: () -> Void
    let onDelete: () -> Void

    private var progress: Double {
        project.progress(with: tasks)
    }

    private var completedTasks: Int {
        tasks.count(where: { $0.isCompleted })
    }

    private var totalTasks: Int {
        tasks.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text(project.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(project.status.displayName)
                        .font(.caption)
                        .foregroundColor(statusColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor.opacity(0.1))
                        .clipShape(Capsule())
                }

                Spacer()

                Menu {
                    Button(action: onEdit) {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button(role: .destructive, action: onDelete) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                }
            }

            // Description
            if !project.description.isEmpty {
                Text(project.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            // Progress
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Progress")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("\(completedTasks)/\(totalTasks) tasks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                ProgressView(value: progress)
                    .tint(progressColor)

                Text("\(Int(progress * 100))% complete")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Target completion date
            if let targetDate = project.targetCompletionDate {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.secondary)
                    Text("Due: \(targetDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }

    private var statusColor: Color {
        switch project.status {
        case .active: .blue
        case .completed: .green
        case .onHold: .orange
        case .cancelled: .red
        }
    }

    private var progressColor: Color {
        if progress >= 0.8 {
            .green
        } else if progress >= 0.5 {
            .yellow
        } else {
            .blue
        }
    }
}

/// View for adding a new project
struct AddProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var color = "blue"
    @State private var targetCompletionDate: Date?

    let onSave: (PlannerProject) -> Void

    private let colors = ["blue", "green", "orange", "red", "purple", "pink"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Project Details") {
                    TextField("Project Name", text: $name)

                    TextEditor(text: $description)
                        .frame(height: 100)
                        .overlay(
                            Text(description.isEmpty ? "Description (optional)" : "")
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                                .allowsHitTesting(false),
                            alignment: .topLeading
                        )
                }

                Section("Appearance") {
                    Picker("Color", selection: $color) {
                        ForEach(colors, id: \.self) { colorName in
                            HStack {
                                Circle()
                                    .fill(Color(colorName) ?? .blue)
                                    .frame(width: 20, height: 20)
                                Text(colorName.capitalized)
                            }
                            .tag(colorName)
                        }
                    }
                }

                Section("Timeline") {
                    Toggle(
                        "Set target completion date",
                        isOn: Binding(
                            get: { targetCompletionDate != nil },
                            set: { if !$0 { targetCompletionDate = nil } }
                        ))

                    if targetCompletionDate != nil {
                        DatePicker(
                            "Target Date",
                            selection: Binding(
                                get: { targetCompletionDate ?? Date() },
                                set: { targetCompletionDate = $0 }
                            ),
                            displayedComponents: .date
                        )
                    }
                }
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveProject()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func saveProject() {
        let project = PlannerProject(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            color: color,
            targetCompletionDate: targetCompletionDate
        )
        onSave(project)
    }
}

#Preview {
    ProjectsView()
}
