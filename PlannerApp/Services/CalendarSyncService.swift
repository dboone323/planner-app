//
// CalendarSyncService.swift
// PlannerApp
//
// Service for syncing with system calendars (EventKit)
//

import EventKit

class CalendarSyncService: ObservableObject {
    static let shared = CalendarSyncService()
    private let eventStore = EKEventStore()
    
    @Published var isAuthorized = false
    
    func requestAccess() {
        eventStore.requestFullAccessToEvents { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
            }
        }
    }
    
    func fetchEvents(for date: Date) -> [EKEvent] {
        guard isAuthorized else { return [] }
        
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        
        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
        return eventStore.events(matching: predicate)
    }
}
