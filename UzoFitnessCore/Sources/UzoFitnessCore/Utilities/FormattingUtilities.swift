import Foundation

// MARK: - Formatting Utilities
public struct FormattingUtilities {
    
    // MARK: - Weight and Volume Formatting
    
    /// Formats weight values for display (e.g., "135.5 lbs")
    public static func formatWeight(_ weight: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: weight)) ?? "0"
    }
    
    /// Formats volume values for display (e.g., "1,350 lbs")
    public static func formatVolume(_ volume: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: volume)) ?? "0"
    }
    
    // MARK: - Time and Duration Formatting
    
    /// Formats duration in seconds to a readable string (e.g., "2:30" for 150 seconds)
    public static func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// Formats time in seconds to a readable string (e.g., "2m 30s" for 150 seconds)
    public static func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        
        if minutes > 0 {
            return "\(minutes)m \(remainingSeconds)s"
        } else {
            return "\(remainingSeconds)s"
        }
    }
    
    /// Formats rest duration for display (e.g., "2:30" for 150 seconds)
    public static func formatRestDuration(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    // MARK: - Value Formatting
    
    /// Formats numeric values for display with specified decimal places
    public static func formatValue(_ value: Double, decimalPlaces: Int = 1) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = decimalPlaces
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
} 