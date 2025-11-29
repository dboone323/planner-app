//
// CloudKitManager.swift
// PlannerApp
//
// Service for iCloud synchronization
//

import CloudKit

class CloudKitManager {
    static let shared = CloudKitManager()
    let container = CKContainer.default()
    let database: CKDatabase
    
    init() {
        self.database = container.privateCloudDatabase
    }
    
    func saveTask(_ task: TaskItem) {
        let record = CKRecord(recordType: "Task")
        record["title"] = task.title as CKRecordValue
        record["isCompleted"] = task.isCompleted as CKRecordValue
        
        database.save(record) { record, error in
            if let error = error {
                print("CloudKit Save Error: \(error)")
            }
        }
    }
    
    func fetchTasks(completion: @escaping ([TaskItem]) -> Void) {
        let query = CKQuery(recordType: "Task", predicate: NSPredicate(value: true))
        
        database.perform(query, inZoneWith: nil) { records, error in
            if let records = records {
                let tasks = records.map { record in
                    TaskItem(
                        title: record["title"] as? String ?? "",
                        priority: .medium,
                        dueDate: nil,
                        isCompleted: record["isCompleted"] as? Bool ?? false
                    )
                }
                DispatchQueue.main.async {
                    completion(tasks)
                }
            }
        }
    }
}
