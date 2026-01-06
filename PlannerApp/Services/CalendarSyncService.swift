//
// CalendarSyncService.swift
// PlannerApp
//
// Service for syncing with system calendars (EventKit)
//

//
// CalendarSyncService.swift
// PlannerApp
//
// Service for syncing with system calendars (EventKit)
//

import EventKit

protocol EventStoreProtocol {
    func requestFullAccessToEvents(completion: @escaping (Bool, Error?) -> Void)
    func predicateForEvents(withStart startDate: Date, end endDate: Date, calendars: [EKCalendar]?) -> NSPredicate
    func events(matching predicate: NSPredicate) -> [EKEvent]
}

extension EKEventStore: EventStoreProtocol {}

class CalendarSyncService: ObservableObject {
    static let shared = CalendarSyncService()
    private let eventStore: EventStoreProtocol
    
    init(eventStore: EventStoreProtocol = EKEventStore()) {
        self.eventStore = eventStore
    }

    @Published var isAuthorized = false

    func requestAccess() {
        eventStore.requestFullAccessToEvents { granted, _ in
            DispatchQueue.main.async {
                self.isAuthorized = granted
            }
        }
    }

    func fetchEvents(for date: Date) -> [EKEvent] {
        guard isAuthorized else { return [] }

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return [] }

        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
        return eventStore.events(matching: predicate)
    }
}
