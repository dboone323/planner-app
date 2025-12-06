//
// BackupManager.swift
// PlannerApp
//
// Service for local backups
//

import Foundation

class BackupManager {
    static let shared = BackupManager()

    func createBackup(tasks: [TaskItem]) -> URL? {
        // Serialize tasks to JSON
        // Save to Documents/Backups
        return nil // Placeholder
    }

    func restoreBackup(from url: URL) {
        // Restore logic
    }
}
