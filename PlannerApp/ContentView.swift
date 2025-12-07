//
//  ContentView.swift
//  PlannerApp
//
//  Updated for Phase 2 Core UX Redesign
//

import SwiftUI

public struct ContentView: View {
    @State private var tasks: [PlannerTask] = []
    @State private var showingAddTask = false
    @State private var refreshID = UUID() // Force refresh

    private let dataManager = TaskDataManager.shared

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                // Background
                #if os(iOS)
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                #else
                Color.gray.opacity(0.1)
                    .ignoresSafeArea()
                #endif

                if tasks.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(tasks) { task in
                                TaskCardView(
                                    task: task,
                                    onToggle: { t in toggleTask(t) },
                                    onEdit: { _ in /* Edit implementation TODO */ }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("My Tasks")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { seedSampleData() }) {
                        Label("Add Sample", systemImage: "plus")
                    }
                }
            }
            .onAppear {
                loadTasks()
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checklist")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))
            Text("All caught up!")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            Text("Tap + to add a new task")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button("Generate Sample Tasks") {
                seedSampleData()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
        }
        .padding()
    }

    private func loadTasks() {
        tasks = dataManager.load().sorted {
            // Sort: High priority first, then due date
            if $0.priority.sortOrder != $1.priority.sortOrder {
                return $0.priority.sortOrder > $1.priority.sortOrder
            }
            return ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture)
        }
    }

    private func toggleTask(_ task: PlannerTask) {
        var updatedTask = task
        updatedTask.isCompleted.toggle()
        dataManager.update(updatedTask)
        // Animate removal or change?
        withAnimation {
            loadTasks()
        }
    }

    private func seedSampleData() {
        let samples = [
            PlannerTask(title: "Review Design Specs", description: "Check color contrast and typography scale.", priority: .high, dueDate: Date().addingTimeInterval(3600 * 4)),
            PlannerTask(title: "Weekly Sync", description: "Team status update meeting.", priority: .medium, dueDate: Date().addingTimeInterval(3600 * 24)),
            PlannerTask(title: "Update Documentation", description: "Reflect recent API changes in the wiki.", priority: .low, dueDate: Date().addingTimeInterval(3600 * 48))
        ]

        for t in samples {
            dataManager.add(t)
        }
        withAnimation {
            loadTasks()
        }
    }
}

#if os(iOS)
import UIKit
#endif

// MARK: - Widget Support (Verification)

struct TasksWidgetView: View {
    let tasks: [PlannerTask]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Priority Tasks")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: "list.bullet.circle.fill")
                    .foregroundColor(.blue)
            }

            if tasks.isEmpty {
                VStack {
                    Spacer()
                    Text("No tasks due")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                VStack(spacing: 8) {
                    ForEach(tasks.prefix(3)) { task in
                        HStack {
                            Circle()
                                .fill(priorityColor(task.priority))
                                .frame(width: 8, height: 8)

                            Text(task.title)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .lineLimit(1)

                            Spacer()

                            if let due = task.dueDate {
                                Text(due, style: .time)
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(6)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
            }
            Spacer()
        }
        .padding()
        #if os(iOS)
        .background(Color(uiColor: .systemBackground))
        #else
        .background(Color.white)
        #endif
    }

    func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
}

#Preview("Widget") {
    TasksWidgetView(tasks: [
        PlannerTask(title: "Urgent Fix", description: "", priority: .high, dueDate: Date()),
        PlannerTask(title: "Client Call", description: "", priority: .medium, dueDate: Date().addingTimeInterval(3600))
    ])
    .frame(width: 170, height: 170)
    .cornerRadius(20)
}
