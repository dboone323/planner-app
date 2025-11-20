//
//  SentimentAnalyticsView.swift
//  PlannerApp
//
//  Sentiment analytics dashboard showing trends, distribution, and insights
//

import Charts
import SwiftUI

public struct SentimentAnalyticsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let entries: [JournalEntry]

    // Computed analytics data
    private var averageSentiment: Double {
        guard !entries.isEmpty else { return 0.0 }
        return entries.reduce(0.0) { $0 + $1.sentimentScore } / Double(entries.count)
    }

    private var sentimentDistribution: [(String, Int)] {
        let positive = entries.count(where: { $0.sentiment == "positive" })
        let neutral = entries.count(where: { $0.sentiment == "neutral" })
        let negative = entries.count(where: { $0.sentiment == "negative" })
        return [
            ("Positive", positive),
            ("Neutral", neutral),
            ("Negative", negative)
        ]
    }

    private var topPositiveEntries: [JournalEntry] {
        entries
            .filter { $0.sentiment == "positive" }
            .sorted { $0.sentimentScore > $1.sentimentScore }
            .prefix(3)
            .map(\.self)
    }

    private var topNegativeEntries: [JournalEntry] {
        entries
            .filter { $0.sentiment == "negative" }
            .sorted { $0.sentimentScore < $1.sentimentScore }
            .prefix(3)
            .map(\.self)
    }

    private var weeklyAverages: [(Date, Double)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: entries) { entry in
            calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: entry.date)
        }

        return grouped.compactMap { components, weekEntries -> (Date, Double)? in
            guard let date = calendar.date(from: components) else { return nil }
            let average = weekEntries.reduce(0.0) { $0 + $1.sentimentScore } / Double(weekEntries.count)
            return (date, average)
        }
        .sorted { $0.0 < $1.0 }
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header with overall sentiment
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sentiment Analytics")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.currentTheme.primaryTextColor)

                    HStack {
                        Text("Overall Average:")
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        Spacer()
                        SentimentBadge(
                            sentiment: sentimentLabel(for: averageSentiment),
                            score: averageSentiment
                        )
                    }
                }
                .padding()
                .background(themeManager.currentTheme.secondaryBackgroundColor)
                .cornerRadius(12)

                // Sentiment Distribution Chart
                if !entries.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sentiment Distribution")
                            .font(.headline)
                            .foregroundColor(themeManager.currentTheme.primaryTextColor)

                        Chart {
                            ForEach(sentimentDistribution, id: \.0) { item in
                                BarMark(
                                    x: .value("Sentiment", item.0),
                                    y: .value("Count", item.1)
                                )
                                .foregroundStyle(colorFor(sentiment: item.0))
                            }
                        }
                        .frame(height: 200)
                        .chartXAxis {
                            AxisMarks(values: .automatic) { _ in
                                AxisValueLabel()
                            }
                        }
                    }
                    .padding()
                    .background(themeManager.currentTheme.secondaryBackgroundColor)
                    .cornerRadius(12)
                }

                // Weekly Trend Chart
                if weeklyAverages.count >= 2 {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Weekly Sentiment Trend")
                            .font(.headline)
                            .foregroundColor(themeManager.currentTheme.primaryTextColor)

                        Chart {
                            ForEach(weeklyAverages, id: \.0) { dataPoint in
                                LineMark(
                                    x: .value("Week", dataPoint.0),
                                    y: .value("Average Sentiment", dataPoint.1)
                                )
                                .foregroundStyle(themeManager.currentTheme.primaryAccentColor)
                                .interpolationMethod(.catmullRom)

                                AreaMark(
                                    x: .value("Week", dataPoint.0),
                                    y: .value("Average Sentiment", dataPoint.1)
                                )
                                .foregroundStyle(themeManager.currentTheme.primaryAccentColor.opacity(0.2))
                                .interpolationMethod(.catmullRom)
                            }
                        }
                        .frame(height: 200)
                        .chartYScale(domain: -1 ... 1)
                        .chartXAxis {
                            AxisMarks(values: .automatic) { _ in
                                AxisValueLabel(format: .dateTime.month().day())
                            }
                        }
                    }
                    .padding()
                    .background(themeManager.currentTheme.secondaryBackgroundColor)
                    .cornerRadius(12)
                }

                // Top Positive Entries
                if !topPositiveEntries.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Most Positive Entries")
                            .font(.headline)
                            .foregroundColor(themeManager.currentTheme.primaryTextColor)

                        ForEach(topPositiveEntries) { entry in
                            EntryPreviewCard(entry: entry)
                                .environmentObject(themeManager)
                        }
                    }
                    .padding()
                    .background(themeManager.currentTheme.secondaryBackgroundColor)
                    .cornerRadius(12)
                }

                // Top Negative Entries
                if !topNegativeEntries.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Entries Needing Attention")
                            .font(.headline)
                            .foregroundColor(themeManager.currentTheme.primaryTextColor)

                        ForEach(topNegativeEntries) { entry in
                            EntryPreviewCard(entry: entry)
                                .environmentObject(themeManager)
                        }
                    }
                    .padding()
                    .background(themeManager.currentTheme.secondaryBackgroundColor)
                    .cornerRadius(12)
                }
            }
            .padding()
        }
        .background(themeManager.currentTheme.primaryBackgroundColor.ignoresSafeArea())
        .navigationTitle("Sentiment Analytics")
    }

    // Helper functions
    private func sentimentLabel(for score: Double) -> String {
        score > 0.2 ? "positive" : (score < -0.2 ? "negative" : "neutral")
    }

    private func colorFor(sentiment: String) -> Color {
        switch sentiment.lowercased() {
        case "positive":
            .green
        case "negative":
            .red
        default:
            .gray
        }
    }
}

// MARK: - Entry Preview Card

struct EntryPreviewCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let entry: JournalEntry

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)
                Spacer()
                SentimentBadge(sentiment: entry.sentiment, score: entry.sentimentScore)
            }

            Text(entry.body)
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                .lineLimit(2)

            Text(entry.date, formatter: dateFormatter)
                .font(.caption2)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor.opacity(0.7))
        }
        .padding(12)
        .background(themeManager.currentTheme.primaryBackgroundColor)
        .cornerRadius(8)
    }
}

// MARK: - Preview

public struct SentimentAnalyticsView_Previews: PreviewProvider {
    public static var previews: some View {
        let sampleEntries = [
            JournalEntry(
                title: "Great Day",
                body: "I had an amazing and wonderful day! Everything was excellent.",
                date: Date().addingTimeInterval(-86400 * 7),
                mood: "😊",
                sentiment: "positive",
                sentimentScore: 0.8
            ),
            JournalEntry(
                title: "Tough Times",
                body: "This was terrible and awful. Everything felt broken.",
                date: Date().addingTimeInterval(-86400 * 5),
                mood: "😢",
                sentiment: "negative",
                sentimentScore: -0.7
            ),
            JournalEntry(
                title: "Regular Day",
                body: "Today was a normal day at work.",
                date: Date().addingTimeInterval(-86400 * 2),
                mood: "😐",
                sentiment: "neutral",
                sentimentScore: 0.0
            )
        ]

        NavigationStack {
            SentimentAnalyticsView(entries: sampleEntries)
                .environmentObject(ThemeManager())
        }
    }
}
