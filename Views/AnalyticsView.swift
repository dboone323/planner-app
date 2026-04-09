import SwiftUI

/// View for displaying productivity analytics and statistics
public struct AnalyticsView: View {
    @State private var tasks: [PlannerTask] = []
    @State private var projects: [PlannerProject] = []
    @State private var selectedTimeRange: TimeRange = .week

    private let taskDataManager = TaskDataManager.shared
    private let projectDataManager = ProjectDataManager.shared

    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case quarter = "Quarter"
        case year = "Year"

        var days: Int {
            switch self {
            case .week: 7
            case .month: 30
            case .quarter: 90
            case .year: 365
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Time range picker
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Statistics cards
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        StatisticCard(
                            title: "Tasks Completed",
                            value: "\(completedTasksCount)",
                            subtitle: "in the last \(selectedTimeRange.rawValue.lowercased())",
                            icon: "checkmark.circle.fill",
                            color: .green
                        )

                        StatisticCard(
                            title: "Completion Rate",
                            value: "\(Int(completionRate * 100))%",
                            subtitle: "of all tasks",
                            icon: "chart.pie.fill",
                            color: .blue
                        )

                        StatisticCard(
                            title: "Active Projects",
                            value: "\(activeProjectsCount)",
                            subtitle: "currently in progress",
                            icon: "folder.fill",
                            color: .orange
                        )

                        StatisticCard(
                            title: "Average Priority",
                            value: averagePriority,
                            subtitle: "task priority level",
                            icon: "exclamationmark.triangle.fill",
                            color: .red
                        )
                    }
                    .padding(.horizontal)

                    // Productivity chart
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Productivity Trend")
                            .font(.headline)
                            .padding(.horizontal)

                        ProductivityChart(tasks: filteredTasks, timeRange: selectedTimeRange)
                            .frame(height: 200)
                            .padding(.horizontal)
                    }

                    // Priority distribution
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Task Priority Distribution")
                            .font(.headline)
                            .padding(.horizontal)

                        PriorityChart(tasks: filteredTasks)
                            .frame(height: 150)
                            .padding(.horizontal)
                    }

                    // Recent activity
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recent Activity")
                            .font(.headline)
                            .padding(.horizontal)

                        RecentActivityView(tasks: recentTasks)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Analytics")
            .background(
                #if os(iOS)
                    Color(uiColor: .systemGroupedBackground)
                        .ignoresSafeArea()
                #else
                    Color.gray.opacity(0.1)
                        .ignoresSafeArea()
                #endif
            )
            .onAppear {
                loadData()
            }
            .onChange(of: selectedTimeRange) { _, _ in
                loadData()
            }
        }
    }

    private var filteredTasks: [PlannerTask] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -selectedTimeRange.days, to: Date()) ?? Date()
        return tasks.filter { $0.createdAt >= cutoffDate }
    }

    private var completedTasksCount: Int {
        filteredTasks.count(where: { $0.isCompleted })
    }

    private var completionRate: Double {
        guard !tasks.isEmpty else { return 0.0 }
        return Double(tasks.count(where: { $0.isCompleted })) / Double(tasks.count)
    }

    private var activeProjectsCount: Int {
        projects.count(where: { $0.status == .active })
    }

    private var averagePriority: String {
        let priorities = tasks.map(\.priority.sortOrder)
        guard !priorities.isEmpty else { return "N/A" }
        let average = Double(priorities.reduce(0, +)) / Double(priorities.count)
        return String(format: "%.1f", average)
    }

    private var recentTasks: [PlannerTask] {
        tasks.sorted { $0.createdAt > $1.createdAt }.prefix(5).map(\.self)
    }

    private func loadData() {
        tasks = taskDataManager.load()
        projects = projectDataManager.load()
    }
}

/// Card displaying a single statistic
struct StatisticCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Spacer()
            }

            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.7))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

/// Simple productivity chart showing task completion over time
struct ProductivityChart: View {
    let tasks: [PlannerTask]
    let timeRange: AnalyticsView.TimeRange

    var body: some View {
        GeometryReader { _ in
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(0..<timeRange.days, id: \.self) { dayOffset in
                    let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date()
                    let dayTasks = tasks.filter { Calendar.current.isDate($0.createdAt, inSameDayAs: date) }
                    let completedCount = dayTasks.count(where: { $0.isCompleted })

                    VStack {
                        Spacer()
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.blue.opacity(0.7))
                            .frame(height: max(CGFloat(completedCount) * 20, 4))
                        Text("\(dayOffset)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

/// Chart showing task priority distribution
struct PriorityChart: View {
    let tasks: [PlannerTask]

    private var priorityCounts: [(TaskPriority, Int)] {
        TaskPriority.allCases.map { priority in
            (priority, tasks.count(where: { $0.priority == priority }))
        }
    }

    var body: some View {
        GeometryReader { _ in
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(priorityCounts, id: \.0) { priority, count in
                    VStack {
                        Spacer()
                        RoundedRectangle(cornerRadius: 4)
                            .fill(priorityColor(priority))
                            .frame(height: max(CGFloat(count) * 15, 4))

                        Text("\(count)")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Text(priority.displayName)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .high: .red
        case .medium: .orange
        case .low: .blue
        }
    }
}

/// View showing recent task activity
struct RecentActivityView: View {
    let tasks: [PlannerTask]

    var body: some View {
        VStack(spacing: 12) {
            ForEach(tasks) { task in
                HStack {
                    Circle()
                        .fill(task.isCompleted ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)

                    VStack(alignment: .leading) {
                        Text(task.title)
                            .font(.subheadline)
                            .lineLimit(1)

                        Text(task.createdAt, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text(task.priority.displayName)
                        .font(.caption)
                        .foregroundColor(priorityColor(task.priority))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(priorityColor(task.priority).opacity(0.1))
                        .clipShape(Capsule())
                }
            }

            if tasks.isEmpty {
                Text("No recent activity")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
    }

    private func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .high: .red
        case .medium: .orange
        case .low: .blue
        }
    }
}

#Preview {
    AnalyticsView()
}
