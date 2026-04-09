import Foundation

/// Service that coordinates task management with notifications
final class TaskNotificationService {
    static let shared = TaskNotificationService()

    private let taskDataManager = TaskDataManager.shared
    private let notificationManager = NotificationManager.shared

    private init() {}

    /// Add a new task and schedule notifications
    /// - Parameter task: The task to add
    func addTask(_ task: PlannerTask) {
        taskDataManager.add(task)

        // Schedule notifications for the new task
        if !task.isCompleted && task.dueDate != nil {
            notificationManager.scheduleReminder(for: task)
            notificationManager.scheduleDueDateNotification(for: task)
        }
    }

    /// Update an existing task and update notifications accordingly
    /// - Parameter task: The updated task
    func updateTask(_ task: PlannerTask) {
        // Get the old task for comparison
        if let oldTask = taskDataManager.find(by: task.id) {
            taskDataManager.update(task)
            notificationManager.updateNotifications(from: oldTask, to: task)
        } else {
            // If old task not found, just update and schedule new notifications
            taskDataManager.update(task)
            if !task.isCompleted && task.dueDate != nil {
                notificationManager.scheduleReminder(for: task)
                notificationManager.scheduleDueDateNotification(for: task)
            }
        }
    }

    /// Delete a task and cancel its notifications
    /// - Parameter task: The task to delete
    func deleteTask(_ task: PlannerTask) {
        notificationManager.cancelNotifications(for: task)
        taskDataManager.delete(task)
    }

    /// Mark a task as completed and cancel its notifications
    /// - Parameter task: The task to complete
    func completeTask(_ task: PlannerTask) {
        var updatedTask = task
        updatedTask.isCompleted = true
        updateTask(updatedTask)
    }

    /// Reschedule all notifications for active tasks
    func rescheduleAllNotifications() {
        let tasks = taskDataManager.load()
        let activeTasks = tasks.filter { !$0.isCompleted && $0.dueDate != nil }
        notificationManager.scheduleNotifications(for: activeTasks)
    }

    /// Cancel all notifications
    func cancelAllNotifications() {
        notificationManager.cancelAllNotifications()
    }
}
