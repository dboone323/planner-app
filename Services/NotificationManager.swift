import Foundation
import UserNotifications

/// Manages notifications for task reminders and due dates
final class NotificationManager {
    static let shared = NotificationManager()

    private let notificationCenter = UNUserNotificationCenter.current()

    private init() {
        requestAuthorization()
    }

    /// Request authorization for notifications
    func requestAuthorization() {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error {
                print("Notification permission denied: \(error.localizedDescription)")
            }
        }
    }

    /// Schedule a reminder notification for a task
    /// - Parameters:
    ///   - task: The task to schedule a reminder for
    ///   - minutesBefore: How many minutes before the due date to show the reminder
    func scheduleReminder(for task: PlannerTask, minutesBefore: Int = 60) {
        guard let dueDate = task.dueDate else { return }

        let reminderDate = dueDate.addingTimeInterval(-Double(minutesBefore * 60))

        // Don't schedule if reminder time is in the past
        guard reminderDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Task Reminder"
        content.body = "\"\(task.title)\" is due soon"
        content.sound = .default
        content.badge = 1

        // Add task details if available
        if !task.description.isEmpty {
            content.body = "\"\(task.title)\" is due soon: \(task.description)"
        }

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(identifier: "task-reminder-\(task.id)", content: content, trigger: trigger)

        notificationCenter.add(request) { error in
            if let error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Scheduled reminder for task: \(task.title)")
            }
        }
    }

    /// Schedule a due date notification for a task
    /// - Parameter task: The task to schedule a due date notification for
    func scheduleDueDateNotification(for task: PlannerTask) {
        guard let dueDate = task.dueDate else { return }

        // Don't schedule if due date is in the past
        guard dueDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Task Due"
        content.body = "\"\(task.title)\" is due now"
        content.sound = .default
        content.badge = 1

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(identifier: "task-due-\(task.id)", content: content, trigger: trigger)

        notificationCenter.add(request) { error in
            if let error {
                print("Error scheduling due date notification: \(error.localizedDescription)")
            } else {
                print("Scheduled due date notification for task: \(task.title)")
            }
        }
    }

    /// Cancel all notifications for a specific task
    /// - Parameter task: The task to cancel notifications for
    func cancelNotifications(for task: PlannerTask) {
        let identifiers = [
            "task-reminder-\(task.id)",
            "task-due-\(task.id)",
        ]
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    /// Cancel all pending notifications
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    /// Schedule notifications for all tasks that have due dates
    /// - Parameter tasks: Array of tasks to schedule notifications for
    func scheduleNotifications(for tasks: [PlannerTask]) {
        for task in tasks {
            if task.dueDate != nil && !task.isCompleted {
                scheduleReminder(for: task)
                scheduleDueDateNotification(for: task)
            }
        }
    }

    /// Update notifications when a task is modified
    /// - Parameters:
    ///   - oldTask: The original task before modification
    ///   - newTask: The updated task
    func updateNotifications(from oldTask: PlannerTask, to newTask: PlannerTask) {
        // Cancel old notifications
        cancelNotifications(for: oldTask)

        // Schedule new notifications if task is not completed and has a due date
        if !newTask.isCompleted && newTask.dueDate != nil {
            scheduleReminder(for: newTask)
            scheduleDueDateNotification(for: newTask)
        }
    }

    /// Get the current notification settings
    func getNotificationSettings(completion: @escaping (UNNotificationSettings) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            completion(settings)
        }
    }

    /// Check if notifications are authorized
    func areNotificationsAuthorized(completion: @escaping (Bool) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            completion(settings.authorizationStatus == .authorized)
        }
    }
}
