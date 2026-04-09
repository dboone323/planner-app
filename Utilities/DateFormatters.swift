import Foundation

public enum AppDateFormatters {
    public static func dateFormatter(style: DateFormatter.Style = .medium) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        return formatter
    }

    public static func timeFormatter(use24Hour: Bool = false) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: use24Hour ? "en_GB" : "en_US")
        return formatter
    }

    public static var monthYearFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }

    public static var fullDateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .full
        return f
    }

    public static var dayFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f
    }

    public static var dayNumberFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f
    }
}
