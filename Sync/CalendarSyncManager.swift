import Foundation
import EventKit

/// Calendar sync manager with bidirectional sync
class CalendarSyncManager {
    private let eventStore = EKEventStore()
    private let calendarIdentifier = "com.plannerapp.sync"
    
    // MARK: - Setup
    
    func setupCalendar() async -> Bool {
        guard await requestAccess() else { return false }
        
        // Create or get sync calendar
        if let _ = findSyncCalendar() {
            return true
        }
        
        return createSyncCalendar()
    }
    
    private func requestAccess() async -> Bool {
        
            return await eventStore.requestFullAccessToEvents()
        } else {
            return await withCheckedContinuation { continuation in
                eventStore.requestAccess(to: .event) { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
        }
    }
    
    private func findSyncCalendar() -> EKCalendar? {
        eventStore.calendars(for: .event).first { calendar in
            calendar.calendarIdentifier == calendarIdentifier
        }
    }
    
    private func createSyncCalendar() -> Bool {
        let calendar = EKCalendar(for: .event, eventStore: eventStore)
        calendar.title = "PlannerApp"
        calendar.source = eventStore.defaultCalendarForNewEvents?.source
        
        do {
            try eventStore.saveCalendar(calendar, commit: true)
            return true
        } catch {
            print("Failed to create calendar: \(error)")
            return false
        }
    }
    
    // MARK: - Sync Tasks to Calendar
    
    func syncTaskToCalendar(_ task: Task) async throws {
        guard let calendar = findSyncCalendar() else {
            throw SyncError.calendarNotFound
        }
        
        // Check if event already exists
        if let existingEvent = findEvent(for: task) {
            try updateEvent(existingEvent, with: task)
        } else {
            try createEvent(for: task, in: calendar)
        }
    }
    
    private func createEvent(for task: Task, in calendar: EKCalendar) throws {
        let event = EKEvent(eventStore: eventStore)
        event.title = task.title
        event.notes = task.notes
        event.calendar = calendar
        event.startDate = task.dueDate
        event.endDate = task.dueDate.addingTimeInterval(task.estimatedDuration)
        event.isAllDay = task.isAllDay
        
        try eventStore.save(event, span: .thisEvent)
        
        // Store event identifier in task
        task.calendarEventId = event.eventIdentifier
    }
    
    private func updateEvent(_ event: EKEvent, with task: Task) throws {
        event.title = task.title
        event.notes = task.notes
        event.startDate = task.dueDate
        event.endDate = task.dueDate.addingTimeInterval(task.estimatedDuration)
        event.isAllDay = task.isAllDay
        
        try eventStore.save(event, span: .thisEvent)
    }
    
    private func findEvent(for task: Task) -> EKEvent? {
        guard let eventId = task.calendarEventId else { return nil }
        return eventStore.event(withIdentifier: eventId)
    }
    
    // MARK: - Delete from Calendar
    
    func deleteTaskFromCalendar(_ task: Task) async throws {
        guard let event = findEvent(for: task) else { return }
        
        try eventStore.remove(event, span: .thisEvent)
        task.calendarEventId = nil
    }
    
    // MARK: - Bidirectional Sync
    
    func performFullSync(tasks: [Task]) async throws -> SyncResult {
        var created = 0
        var updated = 0
        var deleted = 0
        
        // Sync tasks to calendar
        for task in tasks {
            if task.syncToCalendar {
                if task.calendarEventId == nil {
                    try await syncTaskToCalendar(task)
                    created += 1
                } else {
                    try await syncTaskToCalendar(task)
                    updated += 1
                }
            }
        }
        
        // Sync calendar events to tasks (import new events)
        let calendarEvents = fetchRecentEvents()
        for event in calendarEvents {
            if !hasMatchingTask(for: event, in: tasks) {
                // Create new task from calendar event
                _ = createTask(from: event)
                created += 1
            }
        }
        
        return SyncResult(created: created, updated: updated, deleted: deleted)
    }
    
    private func fetchRecentEvents() -> [EKEvent] {
        guard let calendar = findSyncCalendar() else { return [] }
        
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .month, value: 3, to: startDate)!
        
        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: [calendar]
        )
        
        return eventStore.events(matching: predicate)
    }
    
    private func hasMatchingTask(for event: EKEvent, in tasks: [Task]) -> Bool {
        tasks.contains { $0.calendarEventId == event.event Identifier }
    }
    
    private func createTask(from event: EKEvent) -> Task {
        Task(
            title: event.title ?? "",
            dueDate: event.startDate,
            estimatedDuration: event.endDate.timeIntervalSince(event.startDate),
            notes: event.notes,
            calendarEventId: event.eventIdentifier
        )
    }
}

// MARK: - Supporting Types

enum SyncError: Error {
    case calendarNotFound
    case accessDenied
    case syncFailed
}

struct SyncResult {
    let created: Int
    let updated: Int
    let deleted: Int
}

// Mock Task extension for calendar sync
extension Task {
    var calendarEventId: String? {
        get { nil } // Would be stored in SwiftData
        set { }
    }
    
    var syncToCalendar: Bool { true }
    var isAllDay: Bool { estimatedDuration == 0 }
}
