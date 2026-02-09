// filepath: /Users/danielstevens/Desktop/PlannerApp/Views/Calendar/CalendarView.swift
// PlannerApp/Views/Calendar/CalendarView.swift

import Foundation
import SwiftData
import SwiftUI

public struct CalendarView: View {
    // Access shared ThemeManager and data
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.modelContext) private var modelContext

    // Use @Query for automatic SwiftData fetching
    @Query(sort: \SDTask.dueDate) private var sdTasks: [SDTask]
    @Query(sort: \SDGoal.targetDate) private var sdGoals: [SDGoal]

    // Events still use manual loading (not yet migrated to SwiftData)
    @State private var events: [CalendarEvent] = []
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
        calendar.firstWeekday = self.firstDayOfWeekSetting
        return Dictionary(grouping: self.events.sorted(by: { $0.date < $1.date })) { event in
            calendar.startOfDay(for: event.date)
        }
    }

    // Computed property to get dates with goals (using SDGoal)
    private var goalDates: Set<Date> {
        var calendar = Calendar.current
        calendar.firstWeekday = self.firstDayOfWeekSetting
        return Set(self.sdGoals.map { calendar.startOfDay(for: $0.targetDate) })
    }

    // Computed property to get dates with tasks (using SDTask)
    private var taskDates: Set<Date> {
        var calendar = Calendar.current
        calendar.firstWeekday = self.firstDayOfWeekSetting
        return Set(
            self.sdTasks.compactMap { task in
                guard let dueDate = task.dueDate else { return nil }
                return calendar.startOfDay(for: dueDate)
            }
        )
    }

    // Computed property to get dates with events
    private var eventDates: Set<Date> {
        var calendar = Calendar.current
        calendar.firstWeekday = self.firstDayOfWeekSetting
        return Set(self.events.map { calendar.startOfDay(for: $0.date) })
    }

    // Structure for selected date items (using SwiftData types)
    private struct SelectedDateItems {
        let events: [CalendarEvent]
        let goals: [SDGoal]
        let tasks: [SDTask]
    }

    // Get items for selected date
    private var selectedDateItems: SelectedDateItems {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: self.selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay

        let dayEvents = self.events.filter { event in
            event.date >= startOfDay && event.date < endOfDay
        }

        let dayGoals = self.sdGoals.filter { goal in
            calendar.startOfDay(for: goal.targetDate) == startOfDay
        }

        let dayTasks = self.sdTasks.filter { task in
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
        self.use24HourTime ? Self.eventTimeFormatter24Hour : Self.eventTimeFormatter
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
                        Text(Self.monthYearFormatter.string(from: self.selectedDate))
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(self.themeManager.currentTheme.primaryTextColor)

                        Spacer()

                        HStack(spacing: 12) {
                            Button(action: self.previousMonth, label: {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(
                                        self.themeManager.currentTheme.primaryAccentColor
                                    )
                            })
                            .accessibilityLabel(NSLocalizedString(
                                "calendar.previous_month",
                                comment: "Previous month button"
                            ))
                            .accessibilityHint(NSLocalizedString(
                                "calendar.previous_month.hint",
                                comment: "Previous month hint"
                            ))

                            Button(action: self.nextMonth, label: {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(
                                        self.themeManager.currentTheme.primaryAccentColor
                                    )
                            })
                            .accessibilityLabel(NSLocalizedString("calendar.next_month", comment: "Next month button"))
                            .accessibilityHint(NSLocalizedString(
                                "calendar.next_month.hint",
                                comment: "Next month hint"
                            ))
                        }
                    }
                    .padding(.horizontal, 20)

                    // Calendar Grid
                    CalendarGrid(
                        selectedDate: self.$selectedDate,
                        eventDates: self.eventDates,
                        goalDates: self.goalDates,
                        taskDates: self.taskDates,
                        firstDayOfWeek: self.firstDayOfWeekSetting
                    )
                    .environmentObject(self.themeManager)
                }
                .padding(.vertical, 16)
                .background(self.themeManager.currentTheme.secondaryBackgroundColor)

                // Selected Date Details
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(Self.selectedDateFormatter.string(from: self.selectedDate))
                            .font(.headline)
                            .foregroundColor(self.themeManager.currentTheme.primaryTextColor)

                        Spacer()

                        Button {
                            self.showAddEvent = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(self.themeManager.currentTheme.primaryAccentColor)
                                .font(.title2)
                        }
                        .accessibilityLabel(NSLocalizedString("calendar.add_event", comment: "Add event button"))
                        .accessibilityHint(NSLocalizedString("calendar.add_event.hint", comment: "Add event hint"))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    ScrollView {
                        LazyVStack(spacing: 12) {
                            let items = self.selectedDateItems

                            // Events Section
                            if !items.events.isEmpty {
                                DateSectionView(
                                    title: NSLocalizedString("calendar.section.events", comment: "Events section"),
                                    color: .blue
                                ) {
                                    ForEach(items.events) { event in
                                        EventRowView(event: event)
                                            .environmentObject(self.themeManager)
                                    }
                                }
                            }

                            // Goals Section
                            if !items.goals.isEmpty {
                                DateSectionView(
                                    title: NSLocalizedString("calendar.section.goals", comment: "Goals section"),
                                    color: .green
                                ) {
                                    ForEach(items.goals) { goal in
                                        SDGoalRowView(goal: goal)
                                            .environmentObject(self.themeManager)
                                    }
                                }
                            }

                            // Tasks Section
                            if !items.tasks.isEmpty {
                                DateSectionView(
                                    title: NSLocalizedString("calendar.section.tasks", comment: "Tasks section"),
                                    color: .orange
                                ) {
                                    ForEach(items.tasks) { task in
                                        SDTaskRowView(task: task)
                                            .environmentObject(self.themeManager)
                                    }
                                }
                            }

                            // Empty State
                            if items.events.isEmpty, items.goals.isEmpty, items.tasks.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 40))
                                        .foregroundColor(
                                            self.themeManager.currentTheme.secondaryTextColor
                                        )

                                    Text(NSLocalizedString("calendar.empty.no_items", comment: "No items message"))
                                        .font(.subheadline)
                                        .foregroundColor(
                                            self.themeManager.currentTheme.secondaryTextColor
                                        )

                                    Text(NSLocalizedString("calendar.empty.add_hint", comment: "Add event hint"))
                                        .font(.caption)
                                        .foregroundColor(
                                            self.themeManager.currentTheme.secondaryTextColor
                                        )
                                }
                                .padding(.vertical, 40)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .background(self.themeManager.currentTheme.primaryBackgroundColor)
            }
            .background(self.themeManager.currentTheme.primaryBackgroundColor)
            .navigationTitle(NSLocalizedString("calendar.title", comment: "Calendar title"))
            .sheet(isPresented: self.$showAddEvent) {
                AddCalendarEventView(events: self.$events)
                    .environmentObject(self.themeManager)
                    .onDisappear(perform: self.saveEvents)
            }
            .onAppear(perform: self.loadAllData)
            .accentColor(self.themeManager.currentTheme.primaryAccentColor)
        }
    }

    // MARK: - Calendar Navigation

    private func previousMonth() {
        self.selectedDate =
            Calendar.current.date(byAdding: .month, value: -1, to: self.selectedDate)
            ?? self.selectedDate
    }

    private func nextMonth() {
        self.selectedDate =
            Calendar.current.date(byAdding: .month, value: 1, to: self.selectedDate)
            ?? self.selectedDate
    }

    // MARK: - Data Functions

    private func loadAllData() {
        // Only load events manually - tasks and goals are auto-fetched via @Query
        self.events = CalendarDataManager.shared.load()
        print(
            "Calendar data loaded. Events: \(self.events.count), Goals: \(self.sdGoals.count), Tasks: \(self.sdTasks.count)"
        )
    }

    private func saveEvents() {
        CalendarDataManager.shared.save(events: self.events)
        print("Calendar events saved.")
        // Reload events only
        self.events = CalendarDataManager.shared.load()
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
        for _ in 0..<42 {
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
