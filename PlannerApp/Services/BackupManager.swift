//
// BackupManager.swift
// PlannerApp
//
// Service for local backups
//

import Foundation

class BackupManager {
    static let shared = BackupManager()

    func createBackup(tasks _: [TaskItem]) -> URL? {
        // Serialize tasks to JSON
        // Save to Documents/Backups
        nil // Placeholder
    }

    func restoreBackup(from _: URL) {
        // Restore logic
    }
}
