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
    private let ollamaClient: OllamaClient

    public init(ollamaClient: OllamaClient = OllamaClient()) {
        self.ollamaClient = ollamaClient
    }

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

        // 1. Basic Heuristic Analysis
        let highPriority = tasks.filter { $0["priority"] == "high" }
        let overdue = tasks.filter {
            if let days = $0["due_offset_days"].flatMap(Int.init), days < 0 { return true }
            return false
        }

        // 2. AI-Assisted Optimization
        let aiRecommendation = await performScheduleOptimization(
            tasks: tasks,
            preference: preference
        )

        let summary = aiRecommendation ?? buildHeuristicRecommendation(
            tasks: tasks,
            highPriority: highPriority,
            overdue: overdue,
            preference: preference
        )

        return AgentResult(
            agentId: id,
            success: true,
            summary: summary,
            detail: [
                "task_count": "\(tasks.count)",
                "high_priority": "\(highPriority.count)",
                "overdue": "\(overdue.count)",
                "preferred_slot": preference,
                "optimizer": aiRecommendation != nil ? "ollama_quantum" : "heuristic_v1"
            ],
            requiresApproval: !overdue.isEmpty || aiRecommendation != nil
        )
    }

    private func performScheduleOptimization(
        tasks: [[String: String]],
        preference: String
    ) async -> String? {
        let taskList = tasks.map { "- \($0["title"] ?? "Untitled") (Priority: \($0["priority"] ?? "normal"))" }.joined(
            separator: "\n"
        )

        let prompt = """
        Context: Optimization of daily schedule for a user preferring \(preference) focus.
        Remaining Tasks:
        \(taskList)

        Task: Provide a professional, concise scheduling strategy. 
        Focus on resolving priority conflicts and suggesting the best order of execution.
        Return ONLY the recommendation text.
        """

        return await MainActor.run {
            Task {
                do {
                    return try await ollamaClient.generate(
                        model: nil,
                        prompt: prompt,
                        temperature: 0.7,
                        maxTokens: 500,
                        useCache: true
                    )
                } catch {
                    return nil
                }
            }
        }.value
    }

    private func buildHeuristicRecommendation(
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
