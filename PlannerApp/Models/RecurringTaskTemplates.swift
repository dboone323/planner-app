//
// RecurringTaskTemplates.swift
// PlannerApp
//
// Step 36: Recurring task templates.
//

import Foundation
import SwiftData

// MARK: - Recurrence Types

public enum RecurrenceType: String, Codable, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case biweekly = "Bi-weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"
    case weekdays = "Weekdays"
    case weekends = "Weekends"
    case custom = "Custom"
}

// MARK: - Task Template

public struct RecurringTaskTemplate: Codable, Identifiable {
    public var id: UUID
    public var title: String
    public var description: String
    public var priority: String
    public var recurrence: RecurrenceType
    public var customDays: Set<Int>? // For custom recurrence (1=Sunday, 7=Saturday)
    public var reminderOffset: TimeInterval? // Seconds before due
    public var isActive: Bool
    public var lastGenerated: Date?
    public var nextDueDate: Date?

    public init(
        id: UUID = UUID(),
        title: String,
        description: String = "",
        priority: String = "medium",
        recurrence: RecurrenceType = .daily,
        customDays: Set<Int>? = nil,
        reminderOffset: TimeInterval? = nil,
        isActive: Bool = true
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.priority = priority
        self.recurrence = recurrence
        self.customDays = customDays
        self.reminderOffset = reminderOffset
        self.isActive = isActive
        nextDueDate = Self.calculateNextDueDate(from: Date(), recurrence: recurrence, customDays: customDays)
    }

    // MARK: - Date Calculation

    public static func calculateNextDueDate(
        from date: Date,
        recurrence: RecurrenceType,
        customDays: Set<Int>? = nil
    ) -> Date {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        switch recurrence {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: startOfDay)!

        case .biweekly:
            return calendar.date(byAdding: .weekOfYear, value: 2, to: startOfDay)!

        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: startOfDay)!

        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: startOfDay)!

        case .weekdays:
            var nextDate = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            while calendar.isDateInWeekend(nextDate) {
                nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate)!
            }
            return nextDate

        case .weekends:
            var nextDate = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            while !calendar.isDateInWeekend(nextDate) {
                nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate)!
            }
            return nextDate

        case .custom:
            guard let days = customDays, !days.isEmpty else {
                return calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            }

            var nextDate = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            for _ in 0..<7 {
                let weekday = calendar.component(.weekday, from: nextDate)
                if days.contains(weekday) {
                    return nextDate
                }
                nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate)!
            }
            return nextDate
        }
    }
}

// MARK: - Template Manager

final class RecurringTaskTemplateManager: ObservableObject {
    static let shared = RecurringTaskTemplateManager()

    @Published var templates: [RecurringTaskTemplate] = []

    private let userDefaults = UserDefaults.standard
    private let templatesKey = "taskTemplates"

    private init() {
        loadTemplates()
    }

    // MARK: - CRUD

    func addTemplate(_ template: RecurringTaskTemplate) {
        templates.append(template)
        saveTemplates()
    }

    func updateTemplate(_ template: RecurringTaskTemplate) {
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index] = template
            saveTemplates()
        }
    }

    func removeTemplate(id: UUID) {
        templates.removeAll { $0.id == id }
        saveTemplates()
    }

    // MARK: - Generation

    /// Generates tasks from templates that are due.
    func generateDueTasks(in context: ModelContext) -> [SDTask] {
        let now = Date()
        var generated: [SDTask] = []

        for i in templates.indices {
            guard templates[i].isActive,
                  let nextDue = templates[i].nextDueDate,
                  nextDue <= now
            else {
                continue
            }

            let task = SDTask(
                title: templates[i].title,
                taskDescription: templates[i].description,
                priority: templates[i].priority,
                dueDate: nextDue
            )

            context.insert(task)
            generated.append(task)

            // Update template
            templates[i].lastGenerated = now
            templates[i].nextDueDate = RecurringTaskTemplate.calculateNextDueDate(
                from: nextDue,
                recurrence: templates[i].recurrence,
                customDays: templates[i].customDays
            )
        }

        if !generated.isEmpty {
            try? context.save()
            saveTemplates()
        }

        return generated
    }

    // MARK: - Persistence

    private func saveTemplates() {
        if let data = try? JSONEncoder().encode(templates) {
            userDefaults.set(data, forKey: templatesKey)
        }
    }

    private func loadTemplates() {
        if let data = userDefaults.data(forKey: templatesKey),
           let loaded = try? JSONDecoder().decode([RecurringTaskTemplate].self, from: data) {
            templates = loaded
        }
    }
}
