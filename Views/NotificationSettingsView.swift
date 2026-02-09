import SwiftUI

/// View for managing notification settings
struct NotificationSettingsView: View {
    @State private var notificationsEnabled = false
    @State private var reminderMinutesBefore = 60
    @State private var showDueDateNotifications = true

    private let notificationManager = NotificationManager.shared

    var body: some View {
        NavigationStack {
            Form {
                Section("Notification Permissions") {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { _, newValue in
                            if newValue {
                                notificationManager.requestAuthorization()
                            } else {
                                notificationManager.cancelAllNotifications()
                            }
                        }

                    if notificationsEnabled {
                        Text("Notifications are enabled for task reminders and due dates.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Enable notifications to receive reminders for your tasks.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if notificationsEnabled {
                    Section("Reminder Settings") {
                        Picker("Remind me", selection: $reminderMinutesBefore) {
                            Text("15 minutes before").tag(15)
                            Text("30 minutes before").tag(30)
                            Text("1 hour before").tag(60)
                            Text("2 hours before").tag(120)
                            Text("1 day before").tag(1440)
                        }

                        Toggle("Also notify when tasks are due", isOn: $showDueDateNotifications)
                    }

                    Section("Actions") {
                        Button("Reschedule All Notifications") {
                            TaskNotificationService.shared.rescheduleAllNotifications()
                        }
                        .foregroundColor(.blue)

                        Button("Cancel All Notifications") {
                            notificationManager.cancelAllNotifications()
                        }
                        .foregroundColor(.red)
                    }
                }

                Section("About Notifications") {
                    Text(
                        "Task notifications help you stay on top of your deadlines. You'll receive reminders before tasks are due and notifications when they become due."
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Notifications")
            .onAppear {
                checkNotificationStatus()
            }
        }
    }

    private func checkNotificationStatus() {
        notificationManager.areNotificationsAuthorized { authorized in
            DispatchQueue.main.async {
                self.notificationsEnabled = authorized
            }
        }
    }
}

#Preview {
    NotificationSettingsView()
}
