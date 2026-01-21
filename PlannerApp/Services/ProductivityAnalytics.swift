//
// ProductivityAnalytics.swift
// PlannerApp
//
// Service for tracking productivity stats
//

import Foundation

struct DailyStats {
    let date: Date
    let tasksCompleted: Int
    let focusMinutes: Int
}

class ProductivityAnalytics {
    static let shared = ProductivityAnalytics()

    func calculateCompletionRate(tasks: [TaskItem]) -> Double {
        guard !tasks.isEmpty else { return 0.0 }
        let completed = tasks.filter(\.isCompleted).count
        return Double(completed) / Double(tasks.count)
    }

    func getWeeklyFocusHours(stats: [DailyStats]) -> Double {
        let totalMinutes = stats.reduce(0) { $0 + $1.focusMinutes }
        return Double(totalMinutes) / 60.0
    }
}
