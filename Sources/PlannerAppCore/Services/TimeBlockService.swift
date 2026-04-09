//
// TimeBlockService.swift
// PlannerAppCore
//

import Foundation

/// Service for scheduling and managing TimeBlocks.
public class TimeBlockService: @unchecked Sendable {
    @MainActor public static let shared = TimeBlockService()
    
    private var scheduledBlocks: [TimeBlock] = []

    private init() {}

    /// Creates and schedules a new time block.
    @MainActor
    public func createTimeBlock(for task: PlannerTask, start: Date, durationMinutes: Int) -> TimeBlock {
        let block = TimeBlock(
            title: "Focus: \(task.title)",
            startTime: start,
            endTime: start.addingTimeInterval(TimeInterval(durationMinutes * 60)),
            taskId: task.id
        )
        self.scheduledBlocks.append(block)
        return block
    }
    
    /// Schedules an existing time block.
    public func scheduleTimeBlock(_ timeBlock: TimeBlock) {
        self.scheduledBlocks.append(timeBlock)
    }

    /// Returns the list of time blocks for a specific date.
    public func getTimeBlocksForDate(_ date: Date) -> [TimeBlock] {
        let calendar = Calendar.current
        return scheduledBlocks.filter { calendar.isDate($0.startTime, inSameDayAs: date) }
    }
    
    /// Finds available time slots on a given date.
    public func getAvailableTimeSlots(on date: Date) -> [DateInterval] {
        // Real implementation: calculate gaps between scheduled blocks
        return []
    }
}
