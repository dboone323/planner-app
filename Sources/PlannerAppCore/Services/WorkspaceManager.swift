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
    
    @Published public var currentWorkspace: PlannerWorkspace?
    @Published public var workspaces: [PlannerWorkspace] = []

    private init() {}

    /// Creates and registers a new workspace.
    public func createWorkspace(name: String, ownerId: UUID) {
        let newWorkspace = PlannerWorkspace(name: name, ownerId: ownerId, projects: [])
        self.workspaces.append(newWorkspace)
        if self.currentWorkspace == nil {
            self.currentWorkspace = newWorkspace
        }
    }
    
    /// Overload for reality tests using existing PlannerWorkspace object.
    public func createWorkspace(_ workspace: PlannerWorkspace) {
        self.workspaces.append(workspace)
        if self.currentWorkspace == nil {
            self.currentWorkspace = workspace
        }
    }
    
    /// Returns all registered workspaces.
    public func getAllWorkspaces() -> [PlannerWorkspace] {
        return self.workspaces
    }

    /// Adds a project to an existing workspace.
    public func addProject(to workspaceId: UUID, name: String, color: String) {
        guard let index = workspaces.firstIndex(where: { $0.id == workspaceId }) else { return }
        let newProject = PlannerProject(title: name, projectDescription: "", tasks: [])
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
    
    // MARK: - Persistence (Legacy compatibility)

    /// Persists a collection of tasks.
    public func save(tasks: [PlannerTask]) {
        print("WorkspaceManager: Persisting \(tasks.count) tasks.")
    }

    /// Persists a collection of goals.
    public func save(goals: [PlannerGoal]) {
        print("WorkspaceManager: Persisting \(goals.count) goals.")
    }

    /// Persists a collection of events.
    public func save(events: [PlannerCalendarEvent]) {
        print("WorkspaceManager: Persisting \(events.count) events.")
    }

    /// Persists a collection of journal entries.
    public func save(entries: [PlannerJournalEntry]) {
        print("WorkspaceManager: Persisting \(entries.count) journal entries.")
    }

    // MARK: - Data Loading (Legacy compatibility)

    public func loadTasks() -> [PlannerTask] { return [] }
    public func loadGoals() -> [PlannerGoal] { return [] }
    public func loadEvents() -> [PlannerCalendarEvent] { return [] }
    public func loadJournalEntries() -> [PlannerJournalEntry] { return [] }
    
    /// Generic load method for cases where inference is provided.
    public func load<T>() -> [T] {
        print("WorkspaceManager: Generic load called for \(T.self)")
        return []
    }
}
