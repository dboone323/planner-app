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
    func requestFullAccessToEvents(completion: @escaping @Sendable (Bool, Error?) -> Void)
    func predicateForEvents(withStart startDate: Date, end endDate: Date, calendars: [EKCalendar]?) -> NSPredicate
    func events(matching predicate: NSPredicate) -> [EKEvent]
}

extension EKEventStore: EventStoreProtocol {}

class CalendarSyncService: ObservableObject, @unchecked Sendable {
    static let shared = CalendarSyncService()
    private let eventStore: EventStoreProtocol

    init(eventStore: EventStoreProtocol = EKEventStore()) {
        self.eventStore = eventStore
    }

    @Published var isAuthorized = false

    func requestAccess() {
        self.eventStore.requestFullAccessToEvents { granted, _ in
            DispatchQueue.main.async {
                self.isAuthorized = granted
            }
        }
    }

    func fetchEvents(for date: Date) -> [EKEvent] {
        guard self.isAuthorized else { return [] }

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return [] }

        let predicate = self.eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
        return self.eventStore.events(matching: predicate)
    }
}
