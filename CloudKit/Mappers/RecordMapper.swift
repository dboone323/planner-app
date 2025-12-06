//
//  RecordMapper.swift
//  PlannerApp
//
//  Pure logic for mapping between CKRecord and local model types.
//  This file contains no CloudKit I/O operations and is fully unit testable.
//

import CloudKit
import Foundation

/// Protocol for mapping CKRecord to and from local model types
protocol RecordMappable {
    static var recordType: String { get }
    init?(record: CKRecord)
    func toCKRecord() -> CKRecord
}

/// Pure mapping logic for CloudKit records - no I/O operations
struct RecordMapper {

    // MARK: - Task Mapping

    /// Map a CKRecord to a Task model
    /// - Parameter record: The CloudKit record
    /// - Returns: A Task model if mapping succeeds, nil otherwise
    static func mapToTask(from record: CKRecord) -> [String: Any]? {
        guard record.recordType == "Task" else { return nil }

        var taskData: [String: Any] = [:]
        taskData["id"] = record.recordID.recordName
        taskData["title"] = record["title"] as? String ?? ""
        taskData["description"] = record["description"] as? String ?? ""
        taskData["dueDate"] = record["dueDate"] as? Date
        taskData["priority"] = record["priority"] as? Int ?? 0
        taskData["isCompleted"] = record["isCompleted"] as? Bool ?? false
        taskData["createdAt"] = record.creationDate
        taskData["modifiedAt"] = record.modificationDate

        return taskData
    }

    /// Map Task model data to a CKRecord
    /// - Parameters:
    ///   - taskData: Dictionary containing task properties
    ///   - recordID: Optional existing record ID for updates
    /// - Returns: A CKRecord ready to be saved
    static func mapFromTask(_ taskData: [String: Any], recordID: CKRecord.ID? = nil) -> CKRecord {
        let id = recordID ?? CKRecord.ID(recordName: taskData["id"] as? String ?? UUID().uuidString)
        let record = CKRecord(recordType: "Task", recordID: id)

        record["title"] = taskData["title"] as? String
        record["description"] = taskData["description"] as? String
        record["dueDate"] = taskData["dueDate"] as? Date
        record["priority"] = taskData["priority"] as? Int
        record["isCompleted"] = taskData["isCompleted"] as? Bool

        return record
    }

    // MARK: - Goal Mapping

    /// Map a CKRecord to a Goal model
    static func mapToGoal(from record: CKRecord) -> [String: Any]? {
        guard record.recordType == "Goal" else { return nil }

        var goalData: [String: Any] = [:]
        goalData["id"] = record.recordID.recordName
        goalData["title"] = record["title"] as? String ?? ""
        goalData["targetValue"] = record["targetValue"] as? Double ?? 0
        goalData["currentValue"] = record["currentValue"] as? Double ?? 0
        goalData["deadline"] = record["deadline"] as? Date
        goalData["isAchieved"] = record["isAchieved"] as? Bool ?? false
        goalData["createdAt"] = record.creationDate
        goalData["modifiedAt"] = record.modificationDate

        return goalData
    }

    /// Map Goal model data to a CKRecord
    static func mapFromGoal(_ goalData: [String: Any], recordID: CKRecord.ID? = nil) -> CKRecord {
        let id = recordID ?? CKRecord.ID(recordName: goalData["id"] as? String ?? UUID().uuidString)
        let record = CKRecord(recordType: "Goal", recordID: id)

        record["title"] = goalData["title"] as? String
        record["targetValue"] = goalData["targetValue"] as? Double
        record["currentValue"] = goalData["currentValue"] as? Double
        record["deadline"] = goalData["deadline"] as? Date
        record["isAchieved"] = goalData["isAchieved"] as? Bool

        return record
    }

    // MARK: - Calendar Event Mapping

    /// Map a CKRecord to a CalendarEvent model
    static func mapToEvent(from record: CKRecord) -> [String: Any]? {
        guard record.recordType == "CalendarEvent" else { return nil }

        var eventData: [String: Any] = [:]
        eventData["id"] = record.recordID.recordName
        eventData["title"] = record["title"] as? String ?? ""
        eventData["notes"] = record["notes"] as? String ?? ""
        eventData["startDate"] = record["startDate"] as? Date
        eventData["endDate"] = record["endDate"] as? Date
        eventData["isAllDay"] = record["isAllDay"] as? Bool ?? false
        eventData["location"] = record["location"] as? String
        eventData["createdAt"] = record.creationDate
        eventData["modifiedAt"] = record.modificationDate

        return eventData
    }

    /// Map CalendarEvent model data to a CKRecord
    static func mapFromEvent(_ eventData: [String: Any], recordID: CKRecord.ID? = nil) -> CKRecord {
        let id = recordID ?? CKRecord.ID(recordName: eventData["id"] as? String ?? UUID().uuidString)
        let record = CKRecord(recordType: "CalendarEvent", recordID: id)

        record["title"] = eventData["title"] as? String
        record["notes"] = eventData["notes"] as? String
        record["startDate"] = eventData["startDate"] as? Date
        record["endDate"] = eventData["endDate"] as? Date
        record["isAllDay"] = eventData["isAllDay"] as? Bool
        record["location"] = eventData["location"] as? String

        return record
    }

    // MARK: - Journal Entry Mapping

    /// Map a CKRecord to a JournalEntry model
    static func mapToJournalEntry(from record: CKRecord) -> [String: Any]? {
        guard record.recordType == "JournalEntry" else { return nil }

        var entryData: [String: Any] = [:]
        entryData["id"] = record.recordID.recordName
        entryData["title"] = record["title"] as? String ?? ""
        entryData["content"] = record["content"] as? String ?? ""
        entryData["date"] = record["date"] as? Date ?? record.creationDate
        entryData["mood"] = record["mood"] as? String
        entryData["tags"] = record["tags"] as? [String] ?? []
        entryData["createdAt"] = record.creationDate
        entryData["modifiedAt"] = record.modificationDate

        return entryData
    }

    /// Map JournalEntry model data to a CKRecord
    static func mapFromJournalEntry(_ entryData: [String: Any], recordID: CKRecord.ID? = nil) -> CKRecord {
        let id = recordID ?? CKRecord.ID(recordName: entryData["id"] as? String ?? UUID().uuidString)
        let record = CKRecord(recordType: "JournalEntry", recordID: id)

        record["title"] = entryData["title"] as? String
        record["content"] = entryData["content"] as? String
        record["date"] = entryData["date"] as? Date
        record["mood"] = entryData["mood"] as? String
        record["tags"] = entryData["tags"] as? [String]

        return record
    }

    // MARK: - Utility Methods

    /// Extract modification timestamp from a record
    static func modificationDate(from record: CKRecord) -> Date? {
        record.modificationDate
    }

    /// Compare two records to determine which is newer
    static func isNewer(_ record1: CKRecord, than record2: CKRecord) -> Bool {
        guard let date1 = record1.modificationDate,
              let date2 = record2.modificationDate else {
            return false
        }
        return date1 > date2
    }
}
