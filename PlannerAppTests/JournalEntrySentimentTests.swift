//
//  JournalEntrySentimentTests.swift
//  PlannerAppTests
//
//  Test suite for journal entry sentiment analysis
//

@testable import PlannerApp
import SwiftData
import XCTest

@MainActor
final class JournalEntrySentimentTests: XCTestCase {
    var modelContext: ModelContext!
    var modelContainer: ModelContainer!

    override func setUp() async throws {
        let schema = Schema([JournalEntry.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [config])
        modelContext = ModelContext(modelContainer)
    }

    override func tearDown() {
        modelContext = nil
        modelContainer = nil
    }

    func testPositiveSentimentDetection() async {
        let entry = JournalEntry(
            title: "Great Day",
            content: "I had an amazing and wonderful day! Everything was excellent and I feel happy.",
            mood: "happy"
        )

        await entry.analyzeSentiment()

        XCTAssertEqual(entry.sentiment, "positive", "Should detect positive sentiment")
        XCTAssertGreaterThan(entry.sentimentScore, 0.2, "Positive score should be > 0.2")
    }

    func testNegativeSentimentDetection() async {
        let entry = JournalEntry(
            title: "Tough Day",
            content: "This was terrible and awful. Everything felt broken and bad today.",
            mood: "sad"
        )

        await entry.analyzeSentiment()

        XCTAssertEqual(entry.sentiment, "negative", "Should detect negative sentiment")
        XCTAssertLessThan(entry.sentimentScore, -0.2, "Negative score should be < -0.2")
    }

    func testNeutralSentimentDetection() async {
        let entry = JournalEntry(
            title: "Regular Day",
            content: "Today was a normal day. I went to work and came home.",
            mood: "neutral"
        )

        await entry.analyzeSentiment()

        XCTAssertEqual(entry.sentiment, "neutral", "Should detect neutral sentiment")
        XCTAssertLessThanOrEqual(abs(entry.sentimentScore), 0.2, "Neutral score should be close to 0")
    }

    func testSentimentUpdateOnContentChange() async {
        let entry = JournalEntry(
            title: "Changing Mood",
            content: "I love this great day!",
            mood: "happy"
        )

        await entry.updateContent("I love this great day!")

        XCTAssertEqual(entry.sentiment, "positive")

        // Simulate waiting for async sentiment update
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s

        // Content changes should trigger re-analysis
        await entry.updateContent("Everything is terrible and broken.")
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(entry.sentiment, "negative", "Sentiment should update when content changes")
    }

    func testEmptyContentHasNeutralSentiment() async {
        let entry = JournalEntry(
            title: "Empty Entry",
            content: "",
            mood: "neutral"
        )

        await entry.analyzeSentiment()

        XCTAssertEqual(entry.sentiment, "neutral")
        XCTAssertEqual(entry.sentimentScore, 0.0)
    }

    func testSentimentPersistence() async throws {
        let entry = JournalEntry(
            title: "Test Entry",
            content: "I feel amazing and wonderful today!",
            mood: "happy"
        )

        await entry.analyzeSentiment()

        modelContext.insert(entry)
        try modelContext.save()

        // Fetch back from context
        let descriptor = FetchDescriptor<JournalEntry>()
        let entries = try modelContext.fetch(descriptor)

        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.sentiment, "positive")
        XCTAssertGreaterThan(entries.first?.sentimentScore ?? 0, 0)
    }
}
