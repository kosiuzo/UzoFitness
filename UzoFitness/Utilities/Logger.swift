import Foundation
import os.log

/// A wrapper around OSLog to provide a simplified, centralized logging interface.
struct AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.yourapp.default"

    /// Creates a logger for a specific category.
    /// - Parameter category: A string identifying the area of the app the log messages are coming from.
    /// - Returns: An OSLog instance configured with the app's subsystem and the specified category.
    private static func makeLogger(category: String) -> OSLog {
        return OSLog(subsystem: subsystem, category: category)
    }

    /// Logs a debug message.
    /// These messages are for development and debugging, and are not typically visible in release builds.
    /// - Parameters:
    ///   - message: The message to log.
    ///   - category: The category of the log message.
    static func debug(_ message: String, category: String = "default") {
        let log = makeLogger(category: category)
        os_log("%{public}s", log: log, type: .debug, message)
    }

    /// Logs an informational message.
    /// These messages provide general information about the app's state.
    /// - Parameters:
    ///   - message: The message to log.
    ///   - category: The category of the log message.
    static func info(_ message: String, category: String = "default") {
        let log = makeLogger(category: category)
        os_log("%{public}s", log: log, type: .info, message)
    }

    /// Logs an error message.
    /// These messages indicate a problem that has occurred.
    /// - Parameters:
    ///   - message: The error message to log.
    ///   - category: The category of the log message.
    ///   - error: An optional Error object to include in the log.
    static func error(_ message: String, category: String = "default", error: Error? = nil) {
        let log = makeLogger(category: category)
        if let error = error {
            os_log("%{public}s, Error: %{public}s", log: log, type: .error, message, error.localizedDescription)
        } else {
            os_log("%{public}s", log: log, type: .error, message)
        }
    }
}
