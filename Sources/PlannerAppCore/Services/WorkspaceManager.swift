//
// WorkspaceManager.swift
// PlannerAppCore
//

import SwiftUI
import Foundation

/// Service for managing workspaces and hierarchical application data.
@MainActor
public class WorkspaceManager: ObservableObject {
    public static let shared = WorkspaceManager()
    
    @Published public var currentWorkspace: Workspace?
    @Published public var workspaces: [Workspace] = []

    private init() {}

    /// Creates and registers a new workspace.
    public func createWorkspace(name: String, ownerId: UUID) {
        let newWorkspace = Workspace(name: name, ownerId: ownerId, projects: [])
        self.workspaces.append(newWorkspace)
        if self.currentWorkspace == nil {
            self.currentWorkspace = newWorkspace
        }
    }
    
    /// Overload for reality tests using existing Workspace object.
    public func createWorkspace(_ workspace: Workspace) {
        self.workspaces.append(workspace)
        if self.currentWorkspace == nil {
            self.currentWorkspace = workspace
        }
    }
    
    /// Returns all registered workspaces.
    public func getAllWorkspaces() -> [Workspace] {
        return self.workspaces
    }

    /// Adds a project to an existing workspace.
    public func addProject(to workspaceId: UUID, name: String, color: String) {
        guard let index = workspaces.firstIndex(where: { $0.id == workspaceId }) else { return }
        let newProject = Project(name: name, color: color, tasks: [])
        self.workspaces[index].projects.append(newProject)

        if self.currentWorkspace?.id == workspaceId {
            self.currentWorkspace = self.workspaces[index]
        }
    }
    
    /// Returns statistics for workspaces (e.g., project count).
    public func getWorkspaceStatistics() -> [String: Int] {
        var stats: [String: Int] = [:]
        for ws in workspaces {
            stats[ws.name] = ws.projects.count
        }
        return stats
    }
}
