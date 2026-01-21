import SwiftUI

public struct UpcomingItemView: View {
    let item: UpcomingItem
    @EnvironmentObject var themeManager: ThemeManager

    public var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 4) {
                Text(dayFormatter.string(from: item.date))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)

                Text(dayNumberFormatter.string(from: item.date))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.currentTheme.primaryAccentColor)
            }
            .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.currentTheme.primaryTextColor)

                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                }

                Text(timeFormatter.string(from: item.date))
                    .font(.caption2)
                    .foregroundColor(themeManager.currentTheme.secondaryTextColor)
            }

            Spacer()

            Image(systemName: item.icon)
                .foregroundColor(item.color)
                .font(.title3)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.currentTheme.secondaryBackgroundColor)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }

    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }

    private var dayNumberFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
}

#Preview {
    let sampleItem = UpcomingItem(
        title: "Team Meeting",
        subtitle: "Conference Room A",
        date: Date().addingTimeInterval(3600), // 1 hour from now
        icon: "calendar",
        color: .orange
    )

    UpcomingItemView(item: sampleItem)
        .environmentObject(ThemeManager())
}
