//
// TaskTemplateService.swift
// PlannerAppCore
//

import Foundation

/// Service for managing and instantiating task templates.
@MainActor
public class TaskTemplateService: @unchecked Sendable {
    public static let shared = TaskTemplateService()
    
    private var customTemplates: [TaskTemplate] = []

    private init() {}

    /// Returns all available templates.
    public func getTemplates() -> [TaskTemplate] {
        return self.customTemplates + [
            TaskTemplate(
                name: "Bug Report",
                category: .work,
                defaultTitle: "Fix Bug: ",
                defaultPriority: .high,
                defaultTags: ["bug", "dev"],
                checklistItems: ["Reproduce issue", "Identify root cause", "Fix code", "Verify fix"]
            ),
            TaskTemplate(
                name: "Meeting Prep",
                category: .meeting,
                defaultTitle: "Prep for: ",
                defaultPriority: .medium,
                defaultTags: ["meeting", "work"],
                checklistItems: ["Review agenda", "Prepare slides", "Gather metrics"]
            )
        ]
    }
    
    /// Saves a new custom template.
    public func saveTemplate(_ template: TaskTemplate) {
        self.customTemplates.append(template)
    }
    
    /// Returns templates matching a specific category.
    public func getTemplatesForCategory(_ category: TemplateCategory) -> [TaskTemplate] {
        return getTemplates().filter { $0.category == category }
    }
    
    /// Creates a new PlannerTask instance from a template.
    public func createTaskFromTemplate(_ template: TaskTemplate) -> PlannerTask {
        return PlannerTask(
            title: template.defaultTitle,
            taskDescription: "Created from template: \(template.name)",
            priority: template.defaultPriority
        )
    }
}
