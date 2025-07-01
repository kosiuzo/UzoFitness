import Foundation
import SwiftUI

// MARK: - Chart Data Point
struct ChartDataPoint: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let value: Double
    
    init(date: Date, value: Double) {
        self.date = date
        self.value = value
    }
}

// MARK: - Date Range
struct DateRange {
    let startDate: Date
    let endDate: Date
    let displayName: String
    
    init(startDate: Date, endDate: Date, displayName: String) {
        self.startDate = startDate
        self.endDate = endDate
        self.displayName = displayName
    }
    
    static var sixMonths: DateRange {
        let now = Date()
        let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: now) ?? now
        return DateRange(startDate: sixMonthsAgo, endDate: now, displayName: "6 Months")
    }
    
    static var oneYear: DateRange {
        let now = Date()
        let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: now) ?? now
        return DateRange(startDate: oneYearAgo, endDate: now, displayName: "1 Year")
    }
    
    static var twoYears: DateRange {
        let now = Date()
        let twoYearsAgo = Calendar.current.date(byAdding: .year, value: -2, to: now) ?? now
        return DateRange(startDate: twoYearsAgo, endDate: now, displayName: "2 Years")
    }
    
    static func custom(_ start: Date, _ end: Date) -> DateRange {
        DateRange(
            startDate: start,
            endDate: end,
            displayName: "Custom"
        )
    }
    
    static var presets: [DateRange] { [.sixMonths, .oneYear, .twoYears] }
    
    func contains(_ date: Date) -> Bool {
        // Ensure the range always includes "now" so newly added items are not filtered out.
        let effectiveEnd = max(endDate, Date())
        return date >= startDate && date <= effectiveEnd
    }
}

// MARK: - Progress Segment
public enum ProgressSegment: String, CaseIterable, Codable {
    case stats = "stats"
    case pictures = "pictures"
    
    var displayName: String {
        switch self {
        case .stats: return "Stats"
        case .pictures: return "Pictures"
        }
    }
}

// PhotoAngle extension will be added to Enums.swift instead 

enum MetricType: String, CaseIterable, Identifiable {
    case maxWeight = "Max Weight"
    case totalVolume = "Total Volume"
    case totalReps = "Total Reps"
    case totalSessions = "Total Sets"

    var id: String { self.rawValue }
    
    /// A color for the metric, used in charts.
    var color: Color {
        switch self {
        case .maxWeight: return .green
        case .totalVolume: return .purple
        case .totalReps: return .blue
        case .totalSessions: return .orange
        }
    }

    /// Unit string for the metric.
    var unit: String {
        switch self {
        case .maxWeight: return "lbs"
        case .totalVolume: return "lbs"
        case .totalReps: return "reps"
        case .totalSessions: return "sets"
        }
    }
    
    /// Display name for the metric.
    var displayName: String {
        return self.rawValue
    }

    /// Determines if the metric is weight-based (for axis assignment).
    var isWeightBased: Bool {
        switch self {
        case .maxWeight, .totalVolume:
            return true
        case .totalReps, .totalSessions:
            return false
        }
    }
}

// ExerciseTrend is defined in ProgressViewModel.swift to avoid duplication 