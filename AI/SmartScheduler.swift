import EventKit
import Foundation

/// Smart scheduling AI for PlannerApp
class SmartScheduler {
    private let eventStore = EKEventStore()

    // MARK: - Auto Time-Blocking

    func scheduleTask(_ task: Task, preferences: SchedulingPreferences = .default) async -> ScheduledBlock? {
        // Request calendar access
        guard await self.requestCalendarAccess() else {
            return nil
        }

        // Find optimal time slot
        let availableSlots = await findAvailableSlots(
            duration: task.estimatedDuration,
            dueDate: task.dueDate,
            preferences: preferences
        )

        guard let bestSlot = selectBestSlot(availableSlots, for: task, preferences: preferences) else {
            return nil
        }

        // Create calendar event
        let event = EKEvent(eventStore: eventStore)
        event.title = task.title
        event.startDate = bestSlot.start
        event.endDate = bestSlot.end
        event.calendar = self.eventStore.defaultCalendarForNewEvents

        do {
            try self.eventStore.save(event, span: .thisEvent)
            return ScheduledBlock(task: task, start: bestSlot.start, end: bestSlot.end)
        } catch {
            print("Error creating event: \(error)")
            return nil
        }
    }

    // MARK: - Find Available Slots

    private func findAvailableSlots(
        duration: TimeInterval,
        dueDate: Date,
        preferences: SchedulingPreferences
    ) async -> [TimeSlot] {
        let calendar = Calendar.current
        let now = Date()

        // Search window: now until due date
        var searchDate = now
        var availableSlots: [TimeSlot] = []

        while searchDate < dueDate {
            // Check each day
            let dayStart = calendar.startOfDay(for: searchDate)

            // Working hours based on preferences
            guard let workStart = calendar.date(
                bySettingHour: preferences.workStartHour,
                minute: 0,
                second: 0,
                of: dayStart
            ),
                let workEnd = calendar.date(
                    bySettingHour: preferences.workEndHour,
                    minute: 0,
                    second: 0,
                    of: dayStart
                )
            else {
                searchDate = calendar.date(byAdding: .day, value: 1, to: searchDate)!
                continue
            }

            // Get existing events for this day
            let existingEvents = self.getEvents(from: workStart, to: workEnd)

            // Find gaps between events
            let gaps = self.findGaps(between: existingEvents, from: workStart, to: workEnd)

            // Filter gaps that fit the task duration
            for gap in gaps where gap.duration >= duration {
                availableSlots.append(TimeSlot(
                    start: gap.start,
                    end: calendar.date(byAdding: .second, value: Int(duration), to: gap.start)!
                ))
            }

            searchDate = calendar.date(byAdding: .day, value: 1, to: searchDate)!
        }

        return availableSlots
    }

    // MARK: - Select Best Slot

    private func selectBestSlot(
        _ slots: [TimeSlot],
        for task: Task,
        preferences: SchedulingPreferences
    ) -> TimeSlot? {
        guard !slots.isEmpty else { return nil }

        // Score each slot
        let scoredSlots = slots.map { slot -> (slot: TimeSlot, score: Double) in
            var score = 0.0

            // Prefer earlier slots for high priority tasks
            if task.priority == .high {
                let daysUntilSlot = Calendar.current.dateComponents([.day], from: Date(), to: slot.start).day ?? 0
                score += Double(10 - min(10, daysUntilSlot))
            }

            // Prefer morning for focus tasks
            if preferences.preferMorning {
                let hour = Calendar.current.component(.hour, from: slot.start)
                if hour >= 8, hour <= 11 {
                    score += 5.0
                }
            }

            // Avoid late evening
            let hour = Calendar.current.component(.hour, from: slot.start)
            if hour >= 18 {
                score -= 3.0
            }

            // Prefer contiguous blocks
            if slot.duration >= 7200 { // 2 hours
                score += 2.0
            }

            return (slot, score)
        }

        return scoredSlots.max(by: { $0.score < $1.score })?.slot
    }

    // MARK: - Calendar Access

    private func requestCalendarAccess() async -> Bool {
        if #available(iOS 17.0, macOS 14.0, *) {
            let status = await eventStore.requestFullAccessToEvents()
            return status
        } else {
            return await withCheckedContinuation { continuation in
                self.eventStore.requestAccess(to: .event) { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    private func getEvents(from start: Date, to end: Date) -> [EKEvent] {
        let predicate = self.eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
        return self.eventStore.events(matching: predicate)
    }

    private func findGaps(between events: [EKEvent], from: Date, to: Date) -> [TimeSlot] {
        var gaps: [TimeSlot] = []
        var currentTime = from

        let sortedEvents = events.sorted { $0.startDate < $1.startDate }

        for event in sortedEvents {
            if event.startDate > currentTime {
                gaps.append(TimeSlot(start: currentTime, end: event.startDate))
            }
            currentTime = max(currentTime, event.endDate)
        }

        // Final gap until end of work day
        if currentTime < to {
            gaps.append(TimeSlot(start: currentTime, end: to))
        }

        return gaps
    }
}

// MARK: - Supporting Types

struct TimeSlot {
    let start: Date
    let end: Date

    var duration: TimeInterval {
        self.end.timeIntervalSince(self.start)
    }
}

struct ScheduledBlock {
    let task: Task
    let start: Date
    let end: Date
}

struct SchedulingPreferences {
    let workStartHour: Int
    let workEndHour: Int
    let preferMorning: Bool
    let avoidLateEvening: Bool

    static let `default` = SchedulingPreferences(
        workStartHour: 9,
        workEndHour: 17,
        preferMorning: true,
        avoidLateEvening: true
    )
}

/// Mock Task for this implementation
struct Task {
    let title: String
    let estimatedDuration: TimeInterval
    let dueDate: Date
    let priority: TaskPriority
}

enum TaskPriority {
    case low, medium, high
}
