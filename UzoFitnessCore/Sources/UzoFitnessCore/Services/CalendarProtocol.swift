import Foundation

public protocol CalendarProtocol {
    func startOfDay(for date: Date) -> Date
    func date(byAdding component: Calendar.Component, value: Int, to date: Date) -> Date?
} 