import Foundation

// MARK: - Date Formatter Extensions
public extension DateFormatter {
    /// Formatter for month and year display (e.g., "January 2025")
    static let monthYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    /// Formatter for day and month display (e.g., "January 15")
    static let dayMonth: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter
    }()
    
    /// Formatter for weekday display (e.g., "Monday")
    static let weekday: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()
    
    /// Formatter for full date and time display (e.g., "Monday, January 15, 2025 at 2:30 PM")
    static let fullDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter
    }()
} 