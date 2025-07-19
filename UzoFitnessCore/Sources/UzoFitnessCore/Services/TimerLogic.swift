import Foundation

// MARK: - Timer Logic
public struct TimerLogic {
    
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
    
    /// Calculates remaining time for a timer
    public static func calculateRemainingTime(startTime: Date, duration: TimeInterval) -> TimeInterval {
        let elapsed = Date().timeIntervalSince(startTime)
        let remaining = duration - elapsed
        return max(0, remaining)
    }
    
    /// Checks if a timer has expired
    public static func isTimerExpired(startTime: Date, duration: TimeInterval) -> Bool {
        return calculateRemainingTime(startTime: startTime, duration: duration) <= 0
    }
}

// MARK: - Timer Factory Protocol
public protocol TimerFactory {
    func createTimer(interval: TimeInterval, repeats: Bool, block: @escaping (Timer) -> Void) -> Timer
}

// MARK: - Default Timer Factory
public class DefaultTimerFactory: TimerFactory {
    public init() {}
    
    public func createTimer(interval: TimeInterval, repeats: Bool, block: @escaping (Timer) -> Void) -> Timer {
        return Timer.scheduledTimer(withTimeInterval: interval, repeats: repeats, block: block)
    }
} 