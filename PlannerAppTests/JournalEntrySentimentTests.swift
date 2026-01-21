//
//  JournalEntrySentimentTests.swift
//  PlannerAppTests
//
//  Test suite for journal entry sentiment analysis
//

@testable import PlannerApp
import XCTest

final class JournalEntrySentimentTests: XCTestCase {
    func testPositiveSentimentDetection() {
        var entry = JournalEntry(
            title: "Great Day",
            body: "I had an amazing and wonderful day! Everything was excellent and I feel happy.",
            date: Date(),
            mood: "happy"
        )

        entry.analyzeSentiment()

        XCTAssertEqual(entry.sentiment, "positive", "Should detect positive sentiment")
        XCTAssertGreaterThan(entry.sentimentScore, 0.2, "Positive score should be > 0.2")
    }

    func testNegativeSentimentDetection() {
        var entry = JournalEntry(
            title: "Tough Day",
            body: "This was terrible and awful. Everything felt broken and bad today.",
            date: Date(),
            mood: "sad"
        )

        entry.analyzeSentiment()

        XCTAssertEqual(entry.sentiment, "negative", "Should detect negative sentiment")
        XCTAssertLessThan(entry.sentimentScore, -0.2, "Negative score should be < -0.2")
    }

    func testNeutralSentimentDetection() {
        var entry = JournalEntry(
            title: "Regular Day",
            body: "Today was a normal day. I went to work and came home.",
            date: Date(),
            mood: "neutral"
        )

        entry.analyzeSentiment()

        XCTAssertEqual(entry.sentiment, "neutral", "Should detect neutral sentiment")
        XCTAssertLessThanOrEqual(abs(entry.sentimentScore), 0.2, "Neutral score should be close to 0")
    }

    func testSentimentUpdateOnContentChange() {
        var entry = JournalEntry(
            title: "Changing Mood",
            body: "I love this great day!",
            date: Date(),
            mood: "happy"
        )

        entry.updateContent("I love this great day!")

        XCTAssertEqual(entry.sentiment, "positive")

        // Content changes should trigger re-analysis immediately (synchronous)
        entry.updateContent("Everything is terrible and broken.")

        XCTAssertEqual(entry.sentiment, "negative", "Sentiment should update when content changes")
    }

    func testEmptyContentHasNeutralSentiment() {
        var entry = JournalEntry(
            title: "Empty Entry",
            body: "",
            date: Date(),
            mood: "neutral"
        )

        entry.analyzeSentiment()

        XCTAssertEqual(entry.sentiment, "neutral")
        XCTAssertEqual(entry.sentimentScore, 0.0)
    }
}
