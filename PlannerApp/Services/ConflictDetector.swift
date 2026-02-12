//
// ConflictDetector.swift
// PlannerApp
//
// Service for detecting scheduling conflicts
//

import Foundation

class ConflictDetector: @unchecked Sendable {
    static let shared = ConflictDetector()

    func findConflicts(blocks: [TimeBlock]) -> [TimeBlock] {
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
}
