//
// TimeBlockService.swift
// PlannerApp
//
// Service for time blocking tasks
//

import Foundation

struct TimeBlock: Identifiable {
    let id = UUID()
    let taskId: UUID
    let startTime: Date
    let duration: TimeInterval
    var endTime: Date { startTime.addingTimeInterval(duration) }
}

class TimeBlockService {
    static let shared = TimeBlockService()
    
    func createTimeBlock(for task: TaskItem, start: Date, durationMinutes: Int) -> TimeBlock {
        return TimeBlock(
            taskId: task.id,
            startTime: start,
            duration: TimeInterval(durationMinutes * 60)
        )
    }
    
    func getBlocks(for date: Date, blocks: [TimeBlock]) -> [TimeBlock] {
        let calendar = Calendar.current
        return blocks.filter { calendar.isDate($0.startTime, inSameDayAs: date) }
    }
}
