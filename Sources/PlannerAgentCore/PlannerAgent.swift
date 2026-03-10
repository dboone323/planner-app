import Foundation
import SharedKit

/// A `BaseAgent`-compliant scheduling agent for PlannerApp.
///
/// `PlannerAgent` wraps the scheduling intelligence of `SmartScheduler` into
/// the standardized `SharedKit` agent protocol, enabling it to integrate with
/// HITL approval flows and the cross-project `ReviewOrchestrator`.
public struct PlannerAgent: BaseAgent {
    public let id = "planner_agent_001"
    public let name = "Schedule Optimization Agent"

    public init() {}

    /// Analyse a batch of tasks and return a scheduling recommendation.
    ///
    /// Expected context keys:
    /// - `"tasks"`: `[[String: String]]` list of task dicts with keys `"title"`, `"priority"`, `"due_offset_days"`
    /// - `"preferences"`: `String` – `"morning"` | `"afternoon"` | `"evening"` (optional, defaults to morning)
    public func execute(context: [String: any Sendable]) async throws -> AgentResult {
        let tasks = context["tasks"] as? [[String: String]] ?? []
        let preference = context["preferences"] as? String ?? "morning"

        guard !tasks.isEmpty else {
            return AgentResult(
                agentId: id,
                success: false,
                summary: "No tasks provided for scheduling.",
                detail: ["error": "empty_task_list"],
                requiresApproval: false
            )
        }

        // Analyse task load
        let highPriority = tasks.filter { $0["priority"] == "high" }
        let overdue = tasks.filter {
            if let days = $0["due_offset_days"].flatMap(Int.init), days < 0 { return true }
            return false
        }

        let recommendation = buildRecommendation(
            tasks: tasks,
            highPriority: highPriority,
            overdue: overdue,
            preference: preference
        )

        let requiresApproval = !overdue.isEmpty // Overdue tasks need human sign-off
        let success = overdue.isEmpty

        return AgentResult(
            agentId: id,
            success: success,
            summary: recommendation,
            detail: [
                "task_count": "\(tasks.count)",
                "high_priority": "\(highPriority.count)",
                "overdue": "\(overdue.count)",
                "preferred_slot": preference,
            ],
            requiresApproval: requiresApproval
        )
    }

    // MARK: - Private Helpers

    private func buildRecommendation(
        tasks: [[String: String]],
        highPriority: [[String: String]],
        overdue: [[String: String]],
        preference: String
    ) -> String {
        var parts: [String] = []

        if !overdue.isEmpty {
            parts.append("\(overdue.count) overdue task(s) require immediate rescheduling.")
        }
        if !highPriority.isEmpty {
            parts.append("Schedule \(highPriority.count) high-priority task(s) during peak \(preference) focus blocks.")
        }
        let remaining = tasks.count - highPriority.count - overdue.count
        if remaining > 0 {
            parts.append("\(remaining) standard task(s) distributed across available slots.")
        }

        return parts.isEmpty
            ? "All \(tasks.count) tasks are on track. No rescheduling required."
            : parts.joined(separator: " ")
    }
}
