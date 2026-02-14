import _Concurrency
import Foundation
import SwiftUI

public struct DashboardView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var selectedTabTag: String
    @StateObject private var viewModel = DashboardViewModel()
    @AppStorage(AppSettingKeys.userName) private var userName: String = ""
    @AppStorage(AppSettingKeys.use24HourTime) private var use24HourTime: Bool = false
    @AppStorage(AppSettingKeys.dashboardItemLimit) private var dashboardItemLimit: Int = 3

    // Loading and refresh state
    @State private var isRefreshing = false
    @State private var showLoadingOverlay = false

    // Navigation state for quick actions
    @State private var showAddTask = false
    @State private var showAddGoal = false
    @State private var showAddEvent = false
    @State private var showAddJournal = false

    /// Date formatters
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: self.use24HourTime ? "en_GB" : "en_US")
        return formatter
    }

    public var body: some View {
        NavigationStack(path: self.$viewModel.navigationPath) {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Welcome Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(self.greetingText)
                                    .font(.title2)
                                    .fontWeight(.medium)
                                    .foregroundColor(
                                        self.themeManager.currentTheme.primaryTextColor
                                    )

                                if !self.userName.isEmpty {
                                    Text(self.userName)
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(
                                            self.themeManager.currentTheme.primaryAccentColor
                                        )
                                }

                                Text(self.dateFormatter.string(from: Date()))
                                    .font(.subheadline)
                                    .foregroundColor(
                                        self.themeManager.currentTheme.secondaryTextColor
                                    )
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text(self.timeFormatter.string(from: Date()))
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(
                                        self.themeManager.currentTheme.primaryTextColor
                                    )

                                Text(NSLocalizedString("today", comment: "Today label"))
                                    .font(.caption)
                                    .foregroundColor(
                                        self.themeManager.currentTheme.secondaryTextColor
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    // Quick Stats Row
                    HStack(spacing: 16) {
                        QuickStatCard(
                            title: NSLocalizedString("tasks", comment: "Tasks stat card title"),
                            value: "\(self.viewModel.totalTasks)",
                            subtitle: "\(self.viewModel.completedTasks) \(NSLocalizedString("completed", comment: "Completed tasks subtitle"))",
                            icon: "checkmark.circle.fill",
                            color: self.themeManager.currentTheme.primaryAccentColor
                        )

                        QuickStatCard(
                            title: NSLocalizedString("goals", comment: "Goals stat card title"),
                            value: "\(self.viewModel.totalGoals)",
                            subtitle: "\(self.viewModel.completedGoals) \(NSLocalizedString("achieved", comment: "Achieved goals subtitle"))",
                            icon: "target",
                            color: .green
                        )

                        QuickStatCard(
                            title: NSLocalizedString("events", comment: "Events stat card title"),
                            value: "\(self.viewModel.todayEvents)",
                            subtitle: NSLocalizedString("today_suffix", comment: "Today suffix for events"),
                            icon: "calendar",
                            color: .orange
                        )
                    }
                    .padding(.horizontal, 24)

                    // Health Stats (if enabled)
                    if await self.isHealthKitEnabled() {
                        HealthStatsView()
                            .padding(.horizontal, 24)
                    }

                    // Quick Actions
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text(NSLocalizedString("quick_actions", comment: "Quick actions section title"))
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(self.themeManager.currentTheme.primaryTextColor)
                            Spacer()
                        }

                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2),
                            spacing: 16
                        ) {
                            QuickActionCard(
                                title: NSLocalizedString("add_task", comment: "Add task quick action"),
                                icon: "plus.circle.fill",
                                color: self.themeManager.currentTheme.primaryAccentColor
                            ) {
                                self.handleQuickAction(.addTask)
                            }

                            QuickActionCard(
                                title: NSLocalizedString("new_goal", comment: "New goal quick action"),
                                icon: "target",
                                color: .green
                            ) {
                                self.handleQuickAction(.addGoal)
                            }

                            QuickActionCard(
                                title: NSLocalizedString("schedule_event", comment: "Schedule event quick action"),
                                icon: "calendar.badge.plus",
                                color: .orange
                            ) {
                                self.handleQuickAction(.addEvent)
                            }

                            QuickActionCard(
                                title: NSLocalizedString("journal_entry", comment: "Journal entry quick action"),
                                icon: "book.fill",
                                color: .purple
                            ) {
                                self.handleQuickAction(.addJournal)
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    // Recent Activities
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text(NSLocalizedString("recent_activities", comment: "Recent activities section title"))
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(self.themeManager.currentTheme.primaryTextColor)

                            Spacer()

                            Button(NSLocalizedString("view_all", comment: "View all button")) {
                                // For activities we might just use tab selection or a new destination
                                // self.selectedTabTag = "History" // Example
                            }
                            .font(.caption)
                            .foregroundColor(self.themeManager.currentTheme.primaryAccentColor)
                        }

                        LazyVStack(spacing: 12) {
                            ForEach(
                                self.viewModel.recentActivities.prefix(self.dashboardItemLimit),
                                id: \.id
                            ) { activity in
                                ActivityRowView(activity: activity)
                            }

                            if self.viewModel.recentActivities.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "tray")
                                        .font(.system(size: 40))
                                        .foregroundColor(
                                            self.themeManager.currentTheme.secondaryTextColor
                                        )

                                    Text(NSLocalizedString("no_recent_activities", comment: "No recent activities message"))
                                        .font(.subheadline)
                                        .foregroundColor(
                                            self.themeManager.currentTheme.secondaryTextColor
                                        )

                                    Text(NSLocalizedString("start_by_creating", comment: "Start by creating hint"))
                                        .font(.caption)
                                        .foregroundColor(
                                            self.themeManager.currentTheme.secondaryTextColor
                                        )
                                }
                                .padding(.vertical, 40)
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    // Upcoming Items
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text(NSLocalizedString("upcoming", comment: "Upcoming section title"))
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(self.themeManager.currentTheme.primaryTextColor)

                            Spacer()

                            Button(NSLocalizedString("view_calendar", comment: "View calendar button")) {
                                self.selectedTabTag = "Calendar"
                            }
                            .font(.caption)
                            .foregroundColor(self.themeManager.currentTheme.primaryAccentColor)
                        }

                        LazyVStack(spacing: 12) {
                            ForEach(
                                self.viewModel.upcomingItems.prefix(self.dashboardItemLimit),
                                id: \.id
                            ) { item in
                                Button {
                                    if let dest = item.destination {
                                        self.viewModel.navigate(to: dest)
                                    }
                                } label: {
                                    UpcomingItemView(item: item)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }

                            if self.viewModel.upcomingItems.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 40))
                                        .foregroundColor(
                                            self.themeManager.currentTheme.secondaryTextColor
                                        )

                                    Text(NSLocalizedString("nothing_upcoming", comment: "Nothing upcoming message"))
                                        .font(.subheadline)
                                        .foregroundColor(
                                            self.themeManager.currentTheme.secondaryTextColor
                                        )

                                    Text(NSLocalizedString("schedule_events_hint", comment: "Schedule events hint"))
                                        .font(.caption)
                                        .foregroundColor(
                                            self.themeManager.currentTheme.secondaryTextColor
                                        )
                                }
                                .padding(.vertical, 40)
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    // Bottom spacing
                    Color.clear.frame(height: 40)
                }
            }
            #if os(iOS)
            .coordinateSpace(name: "pullToRefresh")
            .refreshable {
                await self.refreshData()
            }
            #endif
            .background(self.themeManager.currentTheme.primaryBackgroundColor.ignoresSafeArea())
            .navigationTitle(NSLocalizedString("dashboard", comment: "Dashboard navigation title"))
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
            #endif
                .navigationDestination(for: DashboardViewModel.Destination.self) { destination in
                    switch destination {
                    case let .taskDetail(id):
                        Text("Task Detail for \(id.uuidString)")
                    case let .goalDetail(id):
                        Text("Goal Detail for \(id.uuidString)")
                    case let .calendarEvent(id):
                        Text("Event Detail for \(id.uuidString)")
                    case .settings:
                        SettingsView()
                    }
                }
                .overlay(
                    Group {
                        if self.showLoadingOverlay {
                            ZStack {
                                Color.black.opacity(0.3)
                                    .ignoresSafeArea()

                                VStack(spacing: 16) {
                                    ProgressView()
                                        .scaleEffect(1.5)
                                        .tint(self.themeManager.currentTheme.primaryAccentColor)

                                    Text(NSLocalizedString("refreshing", comment: "Refreshing loading text"))
                                        .font(.subheadline)
                                        .foregroundColor(
                                            self.themeManager.currentTheme.primaryTextColor
                                        )
                                }
                                .padding(32)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(self.themeManager.currentTheme.secondaryBackgroundColor)
                                        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                                )
                            }
                        }
                    }
                )
        }
        .onAppear {
            _Concurrency.Task { @MainActor in
                await self.refreshData()
            }
        }
        .sheet(isPresented: self.$showAddTask) {
            TaskManagerView()
                .environmentObject(self.themeManager)
        }
        .sheet(isPresented: self.$showAddGoal) {
            AddGoalView(goals: self.$viewModel.allGoals)
                .environmentObject(self.themeManager)
        }
        .sheet(isPresented: self.$showAddEvent) {
            AddCalendarEventView(events: self.$viewModel.allEvents)
                .environmentObject(self.themeManager)
        }
        .sheet(isPresented: self.$showAddJournal) {
            AddJournalEntryView(journalEntries: self.$viewModel.allJournalEntries)
                .environmentObject(self.themeManager)
        }
    }

    // MARK: - Private Methods

    enum QuickAction {
        case addTask, addGoal, addEvent, addJournal
    }

    private func handleQuickAction(_ action: QuickAction) {
        // Add haptic feedback for better UX
        #if os(iOS)
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        #endif

        switch action {
        case .addTask:
            self.showAddTask = true
        case .addGoal:
            self.showAddGoal = true
        case .addEvent:
            self.showAddEvent = true
        case .addJournal:
            self.showAddJournal = true
        }
    }

    @MainActor
    private func refreshData() async {
        guard !self.isRefreshing else { return }
        self.isRefreshing = true
        self.showLoadingOverlay = true
        try? await Task.sleep(nanoseconds: 100_000_000)
        await self.viewModel.refreshData()
        try? await Task.sleep(nanoseconds: 200_000_000)
        self.isRefreshing = false
        self.showLoadingOverlay = false
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return NSLocalizedString("good_morning", comment: "Morning greeting")
        case 12..<17: return NSLocalizedString("good_afternoon", comment: "Afternoon greeting")
        case 17..<22: return NSLocalizedString("good_evening", comment: "Evening greeting")
        default: return NSLocalizedString("good_night", comment: "Night greeting")
        }
    }

    private func isHealthKitEnabled() async -> Bool {
        #if os(iOS)
            let flags = await PlatformFeatureRegistry.shared.flags(for: .iOS)
            return flags.healthKitEnabled
        #else
            return false
        #endif
    }
}

public struct ActivityRowView: View {
    let activity: DashboardActivity
    @EnvironmentObject var themeManager: ThemeManager

    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: self.activity.icon)
                .foregroundColor(self.activity.color)
                .font(.title3)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(self.activity.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(self.themeManager.currentTheme.primaryTextColor)

                Text(self.activity.subtitle)
                    .font(.caption)
                    .foregroundColor(self.themeManager.currentTheme.secondaryTextColor)
            }

            Spacer()

            Text(self.timeAgoString(from: self.activity.timestamp))
                .font(.caption2)
                .foregroundColor(self.themeManager.currentTheme.secondaryTextColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(self.themeManager.currentTheme.secondaryBackgroundColor)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }

    private func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)

        if interval < 60 {
            return NSLocalizedString("now", comment: "Just now")
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return String(format: NSLocalizedString("minutes_ago", comment: "Minutes ago format"), minutes)
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return String(format: NSLocalizedString("hours_ago", comment: "Hours ago format"), hours)
        } else {
            let days = Int(interval / 86400)
            return String(format: NSLocalizedString("days_ago", comment: "Days ago format"), days)
        }
    }
}

#Preview {
    DashboardView(selectedTabTag: .constant("Dashboard"))
        .environmentObject(ThemeManager())
}
