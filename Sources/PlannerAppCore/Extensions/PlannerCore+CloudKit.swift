import Foundation
import CloudKit
import PlannerAppCore

extension PlannerTask {
    public func toCKRecord() -> CKRecord {
        let record = CKRecord(
            recordType: "Task", 
            recordID: CKRecord.ID(recordName: self.id.uuidString)
        )
        record["title"] = self.title
        record["taskDescription"] = self.taskDescription
        record["isCompleted"] = self.isCompleted
        record["priority"] = self.priority.rawValue
        record["dueDate"] = self.dueDate
        record["createdAt"] = self.createdAt
        record["modifiedAt"] = self.modifiedAt
        record["estimatedDuration"] = self.estimatedDuration
        record["sentimentScore"] = self.sentimentScore
        return record
    }
}

extension PlannerGoal {
    public func toCKRecord() -> CKRecord {
        let record = CKRecord(
            recordType: "Goal", 
            recordID: CKRecord.ID(recordName: self.id.uuidString)
        )
        record["title"] = self.title
        record["goalDescription"] = self.goalDescription
        record["targetDate"] = self.targetDate
        record["isCompleted"] = self.isCompleted
        record["priority"] = self.priority.rawValue
        record["progress"] = self.progress
        record["createdAt"] = self.createdAt
        record["modifiedAt"] = self.modifiedAt
        return record
    }
}

extension PlannerJournalEntry {
    public func toCKRecord() -> CKRecord {
        let record = CKRecord(
            recordType: "JournalEntry", 
            recordID: CKRecord.ID(recordName: self.id.uuidString)
        )
        record["title"] = self.title
        record["body"] = self.body
        record["date"] = self.date
        record["mood"] = self.mood
        record["sentiment"] = self.sentiment
        record["sentimentScore"] = self.sentimentScore
        record["createdAt"] = self.createdAt
        record["modifiedAt"] = self.modifiedAt
        return record
    }
}
