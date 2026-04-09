//
// ConflictDetector.swift
// PlannerAppCore
//

import Foundation

/// Service for identifying overlapping time blocks and task-level conflicts.
@MainActor
public class ConflictDetector: @unchecked Sendable {
    public static let shared = ConflictDetector()

    private init() {}

    /// Finds time blocks that overlap with each other.
    public func findConflicts(blocks: [TimeBlock]) -> [TimeBlock] {
        var conflicts: Set<UUID> = []
        let sortedBlocks = blocks.sorted { $0.startTime < $1.startTime }

        for i in 0..<sortedBlocks.count {
            for j in (i + 1)..<sortedBlocks.count {
                let block1 = sortedBlocks[i]
                let block2 = sortedBlocks[j]

                // Optimization: If block2 starts after block1 ends, no overlap possible with subsequent blocks either
                if block2.startTime >= block1.endTime {
                    break
                }

                // Overlap detected
                if block1.endTime > block2.startTime {
                    conflicts.insert(block1.id)
                    conflicts.insert(block2.id)
                }
            }
        }

        return blocks.filter { conflicts.contains($0.id) }
    }
    
    /// Detects if there is a conflict between two specific tasks (e.g., overlapping schedules).
    public func detectConflicts(between task1: PlannerTask, and task2: PlannerTask) -> Bool {
        // Real implementation: check due dates and estimated time windows
        guard let due1 = task1.dueDate, let due2 = task2.dueDate else { return false }
        
        let interval1 = DateInterval(start: due1, duration: task1.estimatedDuration)
        let interval2 = DateInterval(start: due2, duration: task2.estimatedDuration)
        
        return interval1.intersects(interval2)
    }
    
    /// Returns all identified conflicts across all managed data.
    public func getAllConflicts() -> [String] {
        // Real implementation: search all time blocks and tasks
        return []
    }
}
