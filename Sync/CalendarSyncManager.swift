import EventKit
import Foundation

/// Protocol for testing
protocol SyncEventStoreProtocol: AnyObject { // Ideally AnyObject if we use it as class dependency
    func requestAccessToEvents() async -> Bool
    // Update to @Sendable for Swift 6 strict concurrency
    func requestAccess(to entityType: EKEntityType, completion: @escaping @Sendable (Bool, Error?) -> Void)
    func calendars(for entityType: EKEntityType) -> [EKCalendar]
    func saveCalendar(_ calendar: EKCalendar, commit: Bool) throws
    func save(_ event: EKEvent, span: EKSpan) throws
    func remove(_ event: EKEvent, span: EKSpan) throws
    func event(withIdentifier identifier: String) -> EKEvent?
    func predicateForEvents(withStart startDate: Date, end endDate: Date, calendars: [EKCalendar]?) -> NSPredicate
    func events(matching predicate: NSPredicate) -> [EKEvent]
    var defaultCalendarForNewEvents: EKCalendar? { get }

    func newEvent() -> EKEvent
    func newCalendar() -> EKCalendar
}

extension EKEventStore: SyncEventStoreProtocol {
    func newEvent() -> EKEvent {
        EKEvent(eventStore: self)
    }

    func newCalendar() -> EKCalendar {
        EKCalendar(for: .event, eventStore: self)
    }

    func requestAccessToEvents() async -> Bool {
        // Wrapper calls SDK method
        do {
            if #available(iOS 17.0, *) {
                return try await requestFullAccessToEvents()
            } else {
                return await withCheckedContinuation { continuation in
                    self.requestAccess(to: .event) { granted, _ in
                        continuation.resume(returning: granted)
                    }
                }
            }
        } catch {
            return false
        }
    }
}

/// Calendar sync manager with bidirectional sync
class CalendarSyncManager {
    private let eventStore: SyncEventStoreProtocol
    private let calendarIdentifier = "com.plannerapp.sync"

    init(eventStore: SyncEventStoreProtocol = EKEventStore()) {
        self.eventStore = eventStore
    }

    // MARK: - Setup

    func setupCalendar() async -> Bool {
        guard await self.requestAccess() else { return false }

        // Create or get sync calendar
        if self.findSyncCalendar() != nil {
            return true
        }

        return self.createSyncCalendar()
    }

    private func requestAccess() async -> Bool {
        // Simplified for protocol usage
        await self.eventStore.requestAccessToEvents()
    }

    private func findSyncCalendar() -> EKCalendar? {
        self.eventStore.calendars(for: .event).first { calendar in
            calendar.calendarIdentifier == self.calendarIdentifier
        }
    }

    private func createSyncCalendar() -> Bool {
        let calendar = self.eventStore.newCalendar()
        calendar.title = "PlannerApp"
        calendar.source = self.eventStore.defaultCalendarForNewEvents?.source

        do {
            try self.eventStore.saveCalendar(calendar, commit: true)
            return true
        } catch {
            print("Failed to create calendar: \(error)")
            return false
        }
    }

    // MARK: - Sync Tasks to Calendar

    // MARK: - Sync Tasks to Calendar

    func syncTaskToCalendar(_ task: inout PlannerTask) async throws {
        guard let calendar = findSyncCalendar() else {
            throw SyncError.calendarNotFound
        }

        // Check if event already exists
        if let existingEvent = findEvent(for: task) {
            try self.updateEvent(existingEvent, with: task)
        } else {
            try self.createEvent(for: &task, in: calendar)
        }
    }

    private func createEvent(for task: inout PlannerTask, in calendar: EKCalendar) throws {
        let event = self.eventStore.newEvent()
        event.title = task.title
        event.notes = task.description
        event.calendar = calendar
        event.startDate = task.dueDate ?? Date()
        event.endDate = (task.dueDate ?? Date()).addingTimeInterval(task.estimatedDuration)
        event.isAllDay = task.isAllDay

        try self.eventStore.save(event, span: .thisEvent)

        // Store event identifier in task
        task.calendarEventId = event.eventIdentifier
    }

    private func updateEvent(_ event: EKEvent, with task: PlannerTask) throws {
        event.title = task.title
        event.notes = task.description
        event.startDate = task.dueDate
        event.endDate = (task.dueDate ?? Date()).addingTimeInterval(task.estimatedDuration)
        event.isAllDay = task.isAllDay

        try self.eventStore.save(event, span: .thisEvent)
    }

    private func findEvent(for task: PlannerTask) -> EKEvent? {
        guard let eventId = task.calendarEventId else { return nil }
        return self.eventStore.event(withIdentifier: eventId)
    }

    // MARK: - Delete from Calendar

    func deleteTaskFromCalendar(_ task: inout PlannerTask) async throws {
        guard let event = findEvent(for: task) else { return }

        try self.eventStore.remove(event, span: .thisEvent)
        task.calendarEventId = nil
    }

    // MARK: - Bidirectional Sync

    func performFullSync(tasks: inout [PlannerTask]) async throws -> SyncResult {
        var created = 0
        var updated = 0
        let deleted = 0

        // Sync tasks to calendar
        for index in tasks.indices where tasks[index].syncToCalendar {
            if tasks[index].calendarEventId == nil {
                try await syncTaskToCalendar(&tasks[index])
                created += 1
            } else {
                try await syncTaskToCalendar(&tasks[index])
                updated += 1
            }
        }

        // Sync calendar events to tasks (import new events)
        let calendarEvents = self.fetchRecentEvents()
        for event in calendarEvents where !self.hasMatchingTask(for: event, in: tasks) {
            // Create new task from calendar event
            _ = createTask(from: event)
            created += 1
        }

        return SyncResult(created: created, updated: updated, deleted: deleted)
    }

    private func fetchRecentEvents() -> [EKEvent] {
        guard let calendar = findSyncCalendar() else { return [] }

        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .month, value: 3, to: startDate)!

        let predicate = self.eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: [calendar]
        )

        return self.eventStore.events(matching: predicate)
    }

    private func hasMatchingTask(for event: EKEvent, in tasks: [PlannerTask]) -> Bool {
        tasks.contains { $0.calendarEventId == event.eventIdentifier }
    }

    private func createTask(from event: EKEvent) -> PlannerTask {
        PlannerTask(
            title: event.title ?? "",
            description: event.notes ?? "",
            dueDate: event.startDate,
            estimatedDuration: event.endDate.timeIntervalSince(event.startDate),
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

/// Mock Task extension for calendar sync
extension PlannerTask {
    var syncToCalendar: Bool {
        true
    }

    var isAllDay: Bool {
        estimatedDuration == 0
    }
}
