import Foundation

/// Protocol defining the interface for project data management
protocol ProjectDataManaging {
    func load() -> [PlannerProject]
    func save(projects: [PlannerProject])
    func add(_ project: PlannerProject)
    func update(_ project: PlannerProject)
    func delete(_ project: PlannerProject)
    func find(by id: UUID) -> PlannerProject?
}

/// Manages storage and retrieval of `PlannerProject` objects with UserDefaults persistence.
final class ProjectDataManager: ProjectDataManaging {
    /// Shared singleton instance.
    static let shared = ProjectDataManager()

    /// UserDefaults key for storing projects.
    private let projectsKey = "SavedProjects"

    /// UserDefaults instance for persistence.
    private let userDefaults: UserDefaults

    /// Private initializer to enforce singleton usage.
    private init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    /// Loads all projects from UserDefaults.
    /// - Returns: Array of `PlannerProject` objects.
    func load() -> [PlannerProject] {
        guard let data = userDefaults.data(forKey: projectsKey),
              let decodedProjects = try? JSONDecoder().decode([PlannerProject].self, from: data)
        else {
            return []
        }
        return decodedProjects
    }

    /// Saves the provided projects to UserDefaults.
    /// - Parameter projects: Array of `PlannerProject` objects to save.
    func save(projects: [PlannerProject]) {
        if let encoded = try? JSONEncoder().encode(projects) {
            self.userDefaults.set(encoded, forKey: self.projectsKey)
        }
    }

    /// Adds a new project to the stored projects.
    /// - Parameter project: The `PlannerProject` to add.
    func add(_ project: PlannerProject) {
        var projects = self.load()
        projects.append(project)
        self.save(projects: projects)
    }

    /// Updates an existing project in the stored projects.
    /// - Parameter project: The `PlannerProject` to update.
    func update(_ project: PlannerProject) {
        var projects = self.load()
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index] = project
            self.save(projects: projects)
        }
    }

    /// Deletes a project from the stored projects.
    /// - Parameter project: The `PlannerProject` to delete.
    func delete(_ project: PlannerProject) {
        var projects = self.load()
        projects.removeAll { $0.id == project.id }
        self.save(projects: projects)
    }

    /// Finds a project by its ID.
    /// - Parameter id: The UUID of the project to find.
    /// - Returns: The `PlannerProject` if found, otherwise nil.
    func find(by id: UUID) -> PlannerProject? {
        let projects = self.load()
        return projects.first { $0.id == id }
    }

    /// Gets all active projects.
    /// - Returns: Array of active `PlannerProject` objects.
    func getActiveProjects() -> [PlannerProject] {
        let projects = self.load()
        return projects.filter { $0.status == .active }
    }

    /// Gets projects by status.
    /// - Parameter status: The status to filter by.
    /// - Returns: Array of `PlannerProject` objects with the specified status.
    func getProjects(by status: PlannerProject.ProjectStatus) -> [PlannerProject] {
        let projects = self.load()
        return projects.filter { $0.status == status }
    }
}
