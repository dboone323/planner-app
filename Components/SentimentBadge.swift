//
//  SentimentBadge.swift
//  PlannerApp
//
//  Visual badge component displaying sentiment analysis results
//

import SwiftUI

public struct SentimentBadge: View {
    let sentiment: String
    let score: Double

    public init(sentiment: String, score: Double) {
        self.sentiment = sentiment
        self.score = score
    }

    public var body: some View {
        HStack(spacing: 4) {
            Image(systemName: sentimentIcon)
                .font(.caption2)
            Text(sentiment.capitalized)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundStyle(sentimentColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(sentimentColor.opacity(0.15))
        .clipShape(Capsule())
    }

    private var sentimentIcon: String {
        switch sentiment.lowercased() {
        case "positive":
            "face.smiling"
        case "negative":
            "face.dashed"
        default:
            "minus.circle"
        }
    }

    private var sentimentColor: Color {
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

#Preview("Positive") {
    SentimentBadge(sentiment: "positive", score: 0.8)
}

#Preview("Negative") {
    SentimentBadge(sentiment: "negative", score: -0.6)
}

#Preview("Neutral") {
    SentimentBadge(sentiment: "neutral", score: 0.0)
}
