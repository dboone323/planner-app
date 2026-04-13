//
// CalendarSyncService.swift
// PlannerAppCore
//

import EventKit
import Foundation

/// Service for syncing with system calendars (EventKit)
public class CalendarSyncService: ObservableObject, @unchecked Sendable {
    @MainActor public static let shared = CalendarSyncService()
    private let eventStore: EKEventStore

    public init(eventStore: EKEventStore = EKEventStore()) {
        self.eventStore = eventStore
    }

    @Published public var isAuthorized = false

    /// Request full access to the user's calendar events
    @MainActor
    public func requestAccess() {
        if #available(iOS 17.0, *) {
            self.eventStore.requestFullAccessToEvents { [weak self] granted, _ in
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                }
            }
        } else {
            self.eventStore.requestAccess(to: .event) { [weak self] granted, _ in
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                }
            }
        }
    }
    
    /// Syncs a local PlannerCalendarEvent model to the system calendar
    public func syncEvent(_ event: PlannerCalendarEvent) {
        // guard self.isAuthorized else { return }
        // Real implementation would convert PlannerCalendarEvent to EKEvent and save.
    }

    /// Fetches all events for a specific date
    public func fetchEvents(for date: Date) -> [EKEvent] {
        // guard self.isAuthorized else { return [] }

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return [] }

        let predicate = self.eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
        return self.eventStore.events(matching: predicate)
    }
    
    /// Returns the events matching a specific date (alias for fetchEvents)
    public func getEventsForDate(_ date: Date) -> [PlannerCalendarEvent] {
        return fetchEvents(for: date).map { PlannerCalendarEvent(title: $0.title ?? "", date: $0.startDate) }
    }
    
    /// Detects conflicts for a given event in the real system calendar
    public func getConflictingEvents(for event: PlannerCalendarEvent) -> [PlannerCalendarEvent] {
        // guard self.isAuthorized else { return [] }
        // Real implementation: search for overlapping EKEvent objects
        return []
    }
}
