//
// WorkspaceManager.swift
// PlannerApp
//
// Service for managing workspaces and projects
//

import Foundation

struct Workspace: Identifiable {
    let id = UUID()
    let name: String
    let ownerId: UUID
    var projects: [Project]
}

struct Project: Identifiable {
    let id = UUID()
    let name: String
    let color: String
    var tasks: [TaskItem]
}

class WorkspaceManager: ObservableObject {
    @Published var currentWorkspace: Workspace?
    @Published var workspaces: [Workspace] = []

    func createWorkspace(name: String, ownerId: UUID) {
        let newWorkspace = Workspace(name: name, ownerId: ownerId, projects: [])
        workspaces.append(newWorkspace)
        if currentWorkspace == nil {
            currentWorkspace = newWorkspace
        }
    }

    func addProject(to workspaceId: UUID, name: String, color: String) {
        guard let index = workspaces.firstIndex(where: { $0.id == workspaceId }) else { return }
        let newProject = Project(name: name, color: color, tasks: [])
        workspaces[index].projects.append(newProject)

        if currentWorkspace?.id == workspaceId {
            currentWorkspace = workspaces[index]
        }
    }
}
