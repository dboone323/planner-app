// MARK: - Journal Entry Model

import CloudKit
import Foundation

public struct JournalEntry: Identifiable, Codable {
    public let id: UUID
    var title: String
    var body: String
    var date: Date
    var mood: String
    var modifiedAt: Date? // Added for CloudKit sync/merge

    // Sentiment analysis properties
    var sentiment: String // "positive", "negative", or "neutral"
    var sentimentScore: Double // -1.0 to 1.0

    init(
        id: UUID = UUID(),
        title: String,
        body: String,
        date: Date,
        mood: String,
        modifiedAt: Date? = Date(),
        sentiment: String = "neutral",
        sentimentScore: Double = 0.0
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.date = date
        self.mood = mood
        self.modifiedAt = modifiedAt
        self.sentiment = sentiment
        self.sentimentScore = sentimentScore
    }

    // MARK: - Sentiment Analysis

    /// Update entry content and trigger sentiment analysis
    mutating func updateContent(_ newContent: String) {
        self.body = newContent
        self.modifiedAt = Date()

        // Analyze sentiment synchronously
        analyzeSentiment()
    }

    /// Analyze sentiment of entry body using keyword-based scoring
    mutating func analyzeSentiment() {
        // Inline keyword-based sentiment analysis
        let lower = body.lowercased()
        let positives = [
            "love", "great", "excellent", "happy", "good", "amazing", "wonderful", "fast", "clean"
        ]
        let negatives = [
            "hate", "bad", "terrible", "slow", "bug", "broken", "awful", "poor", "crash"
        ]
        let positiveCount = positives.reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
        let negativeCount = negatives.reduce(0) { $0 + (lower.contains($1) ? 1 : 0) }
        let rawScore = Double(positiveCount - negativeCount)
        let normalizedScore = max(-1.0, min(1.0, rawScore / 5.0))

        self.sentimentScore = normalizedScore
        self.sentiment = normalizedScore > 0.2 ? "positive" : (normalizedScore < -0.2 ? "negative" : "neutral")
    }

    // MARK: - CloudKit Conversion

    /// Convert to CloudKit record for syncing
    func toCKRecord() -> CKRecord {
        let record = CKRecord(
            recordType: "JournalEntry", recordID: CKRecord.ID(recordName: id.uuidString)
        )
        record["title"] = title
        record["body"] = body
        record["date"] = date
        record["mood"] = mood
        record["modifiedAt"] = modifiedAt
        record["sentiment"] = sentiment
        record["sentimentScore"] = sentimentScore
        return record
    }

    /// Create a JournalEntry from CloudKit record
    static func from(ckRecord: CKRecord) throws -> JournalEntry {
        guard let title = ckRecord["title"] as? String,
              let body = ckRecord["body"] as? String,
              let date = ckRecord["date"] as? Date,
              let mood = ckRecord["mood"] as? String,
              let id = UUID(uuidString: ckRecord.recordID.recordName)
        else {
            throw NSError(
                domain: "JournalEntryConversionError", code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey: "Failed to convert CloudKit record to JournalEntry"
                ]
            )
        }

        return JournalEntry(
            id: id,
            title: title,
            body: body,
            date: date,
            mood: mood,
            modifiedAt: ckRecord["modifiedAt"] as? Date,
            sentiment: ckRecord["sentiment"] as? String ?? "neutral",
            sentimentScore: ckRecord["sentimentScore"] as? Double ?? 0.0
        )
    }
}
