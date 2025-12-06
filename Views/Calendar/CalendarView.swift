// filepath: /Users/danielstevens/Desktop/PlannerApp/Views/Calendar/CalendarView.swift
// PlannerApp/Views/Calendar/CalendarView.swift

import Foundation
import SwiftUI

public struct CalendarView: View {
    // Access shared ThemeManager and data
    @EnvironmentObject var themeManager: ThemeManager
    @State private var events: [CalendarEvent] = []
    @State private var goals: [Goal] = []
    @State private var tasks: [PlannerTask] = []
    @State private var showAddEvent = false
    @State private var selectedDate = Date()
    @State private var showingDateDetails = false

    // Settings from UserDefaults
    @AppStorage(AppSettingKeys.firstDayOfWeek) private var firstDayOfWeekSetting: Int = Calendar
        .current.firstWeekday
    @AppStorage(AppSettingKeys.use24HourTime) private var use24HourTime: Bool = false

    // Computed property to group events by the start of their day
    private var groupedEvents: [Date: [CalendarEvent]] {
        var calendar = Calendar.current
        calendar.firstWeekday = firstDayOfWeekSetting
        return Dictionary(grouping: events.sorted(by: { $0.date < $1.date })) { event in
            calendar.startOfDay(for: event.date)
        }
    }

    // Computed property to get dates with goals
    private var goalDates: Set<Date> {
        var calendar = Calendar.current
        calendar.firstWeekday = firstDayOfWeekSetting
        return Set(goals.map { calendar.startOfDay(for: $0.targetDate) })
    }

    // Computed property to get dates with tasks
    private var taskDates: Set<Date> {
        var calendar = Calendar.current
        calendar.firstWeekday = firstDayOfWeekSetting
        return Set(
            tasks.compactMap { task in
                guard let dueDate = task.dueDate else { return nil }
                return calendar.startOfDay(for: dueDate)
            }
        )
    }

    // Computed property to get dates with events
    private var eventDates: Set<Date> {
        var calendar = Calendar.current
        calendar.firstWeekday = firstDayOfWeekSetting
        return Set(events.map { calendar.startOfDay(for: $0.date) })
    }

    // Structure for selected date items
    private struct SelectedDateItems {
        let events: [CalendarEvent]
        let goals: [Goal]
        let tasks: [PlannerTask]
    }

    // Get items for selected date
    private var selectedDateItems: SelectedDateItems {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay

        let dayEvents = events.filter { event in
            event.date >= startOfDay && event.date < endOfDay
        }

        let dayGoals = goals.filter { goal in
            calendar.startOfDay(for: goal.targetDate) == startOfDay
        }

        let dayTasks = tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return calendar.startOfDay(for: dueDate) == startOfDay
        }

        return SelectedDateItems(events: dayEvents, goals: dayGoals, tasks: dayTasks)
    }

    // Date Formatters - Cached for performance
    private static let eventTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    private static let eventTimeFormatter24Hour: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "en_GB")
        return formatter
    }()

    private var currentEventTimeFormatter: DateFormatter {
        use24HourTime ? Self.eventTimeFormatter24Hour : Self.eventTimeFormatter
    }

    private static let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    private static let selectedDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }()

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Calendar Widget
                VStack(spacing: 16) {
                    // Calendar Header
                    HStack {
                        Text(Self.monthYearFormatter.string(from: selectedDate))
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(themeManager.currentTheme.primaryTextColor)

                        Spacer()

                        HStack(spacing: 12) {
                            Button(action: previousMonth, label: {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(
                                        themeManager.currentTheme.primaryAccentColor
                                    )
                            })
                            .accessibilityLabel(NSLocalizedString("calendar.previous_month", comment: "Previous month button"))
                            .accessibilityHint(NSLocalizedString("calendar.previous_month.hint", comment: "Previous month hint"))

                            Button(action: nextMonth, label: {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(
                                        themeManager.currentTheme.primaryAccentColor
                                    )
                            })
                            .accessibilityLabel(NSLocalizedString("calendar.next_month", comment: "Next month button"))
                            .accessibilityHint(NSLocalizedString("calendar.next_month.hint", comment: "Next month hint"))
                        }
                    }
                    .padding(.horizontal, 20)

                    // Calendar Grid
                    CalendarGrid(
                        selectedDate: $selectedDate,
                        eventDates: eventDates,
                        goalDates: goalDates,
                        taskDates: taskDates,
                        firstDayOfWeek: firstDayOfWeekSetting
                    )
                    .environmentObject(themeManager)
                }
                .padding(.vertical, 16)
                .background(themeManager.currentTheme.secondaryBackgroundColor)

                // Selected Date Details
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(Self.selectedDateFormatter.string(from: selectedDate))
                            .font(.headline)
                            .foregroundColor(themeManager.currentTheme.primaryTextColor)

                        Spacer()

                        Button {
                            showAddEvent = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(themeManager.currentTheme.primaryAccentColor)
                                .font(.title2)
                        }
                        .accessibilityLabel(NSLocalizedString("calendar.add_event", comment: "Add event button"))
                        .accessibilityHint(NSLocalizedString("calendar.add_event.hint", comment: "Add event hint"))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    ScrollView {
                        LazyVStack(spacing: 12) {
                            let items = selectedDateItems

                            // Events Section
                            if !items.events.isEmpty {
                                DateSectionView(title: NSLocalizedString("calendar.section.events", comment: "Events section"), color: .blue) {
                                    ForEach(items.events) { event in
                                        EventRowView(event: event)
                                            .environmentObject(themeManager)
                                    }
                                }
                            }

                            // Goals Section
                            if !items.goals.isEmpty {
                                DateSectionView(title: NSLocalizedString("calendar.section.goals", comment: "Goals section"), color: .green) {
                                    ForEach(items.goals) { goal in
                                        GoalRowView(goal: goal)
                                            .environmentObject(themeManager)
                                    }
                                }
                            }

                            // Tasks Section
                            if !items.tasks.isEmpty {
                                DateSectionView(title: NSLocalizedString("calendar.section.tasks", comment: "Tasks section"), color: .orange) {
                                    ForEach(items.tasks) { task in
                                        TaskRowView(task: task)
                                            .environmentObject(themeManager)
                                    }
                                }
                            }

                            // Empty State
                            if items.events.isEmpty, items.goals.isEmpty, items.tasks.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 40))
                                        .foregroundColor(
                                            themeManager.currentTheme.secondaryTextColor
                                        )

                                    Text(NSLocalizedString("calendar.empty.no_items", comment: "No items message"))
                                        .font(.subheadline)
                                        .foregroundColor(
                                            themeManager.currentTheme.secondaryTextColor
                                        )

                                    Text(NSLocalizedString("calendar.empty.add_hint", comment: "Add event hint"))
                                        .font(.caption)
                                        .foregroundColor(
                                            themeManager.currentTheme.secondaryTextColor
                                        )
                                }
                                .padding(.vertical, 40)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .background(themeManager.currentTheme.primaryBackgroundColor)
            }
            .background(themeManager.currentTheme.primaryBackgroundColor)
            .navigationTitle(NSLocalizedString("calendar.title", comment: "Calendar title"))
            .sheet(isPresented: $showAddEvent) {
                AddCalendarEventView(events: $events)
                    .environmentObject(themeManager)
                    .onDisappear(perform: saveEvents)
            }
            .onAppear(perform: loadAllData)
            .accentColor(themeManager.currentTheme.primaryAccentColor)
        }
    }

    // MARK: - Calendar Navigation

    private func previousMonth() {
        selectedDate =
            Calendar.current.date(byAdding: .month, value: -1, to: selectedDate)
                ?? selectedDate
    }

    private func nextMonth() {
        selectedDate =
            Calendar.current.date(byAdding: .month, value: 1, to: selectedDate)
                ?? selectedDate
    }

    // MARK: - Data Functions

    private func loadAllData() {
        events = CalendarDataManager.shared.load()
        goals = GoalDataManager.shared.load()
        tasks = TaskDataManager.shared.load()
        print(
            "Calendar data loaded. Events: \(events.count), Goals: \(goals.count), Tasks: \(tasks.count)"
        )
    }

    private func saveEvents() {
        CalendarDataManager.shared.save(events: events)
        print("Calendar events saved.")
        loadAllData()
    }
}

// MARK: - Calendar Extension

extension Calendar {
    func generateDatesInMonth(for date: Date, firstDayOfWeek: Int) -> [Date] {
        guard let monthInterval = dateInterval(of: .month, for: date) else { return [] }

        let monthStart = monthInterval.start
        let firstWeekday = component(.weekday, from: monthStart)
        let daysFromPreviousMonth = (firstWeekday - firstDayOfWeek + 7) % 7

        guard
            let calendarStart = self.date(
                byAdding: .day, value: -daysFromPreviousMonth, to: monthStart
            )
        else { return [] }

        var dates: [Date] = []
        var currentDate = calendarStart
        // Fill a 6x7 (42-day) grid starting at calendarStart
        for _ in 0 ..< 42 {
            dates.append(currentDate)
            guard let nextDate = self.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }

        return dates
    }
}

// MARK: - Preview Provider

public struct CalendarView_Previews: PreviewProvider {
    public static var previews: some View {
        CalendarView()
            .environmentObject(ThemeManager())
    }
}
