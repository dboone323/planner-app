import Foundation
import SharedKit
import PlannerAgentCore

@available(macOS 15.0, *)
@main
struct ScheduleAudit {
    static func main() async {
        print(">>> [PlannerApp Agent] Starting Schedule Optimization task...")

        let agent = PlannerAgent()

        // Simulate a realistic task backlog with priorities and due dates
        let context: [String: Sendable] = [
            "tasks": [
                ["title": "Q1 Report", "priority": "high", "due_offset_days": "2"],
                ["title": "Team Standup Prep", "priority": "high", "due_offset_days": "1"],
                ["title": "Reply to emails", "priority": "normal", "due_offset_days": "0"],
                ["title": "Review PR #47", "priority": "normal", "due_offset_days": "3"],
                ["title": "Update roadmap", "priority": "normal", "due_offset_days": "-1"],  // Overdue
            ] as [[String: String]],
            "preferences": "morning"
        ]

        print(">>> [Task] Analysing 5 tasks for optimal scheduling...")
        do {
            let result = try await agent.execute(context: context)
            print("\n--- Agent Result: \(result.agentId) ---")
            print("Status: \(result.success ? "SUCCESS" : "NEEDS ATTENTION")")
            print("Summary: \(result.summary)")
            print("Task Count: \(result.detail["task_count"] ?? "N/A")")
            print("High Priority: \(result.detail["high_priority"] ?? "0")")
            print("Overdue: \(result.detail["overdue"] ?? "0")")
            print("Preferred Slot: \(result.detail["preferred_slot"] ?? "N/A")")
            print("Requires Approval: \(result.requiresApproval)")
            print("Timestamp: \(result.timestamp)")
        } catch {
            print("Error executing agent: \(error)")
        }

        print("\n>>> [PlannerApp Agent] Task completed.")
    }
}
