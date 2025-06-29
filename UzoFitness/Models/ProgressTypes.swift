import Foundation

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
    
    static let sixMonths = DateRange(
        startDate: Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date(),
        endDate: Date(),
        displayName: "6 Months"
    )
    
    static let oneYear = DateRange(
        startDate: Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date(),
        endDate: Date(),
        displayName: "1 Year"
    )
    
    static let twoYears = DateRange(
        startDate: Calendar.current.date(byAdding: .year, value: -2, to: Date()) ?? Date(),
        endDate: Date(),
        displayName: "2 Years"
    )
    
    static func custom(_ start: Date, _ end: Date) -> DateRange {
        DateRange(
            startDate: start,
            endDate: end,
            displayName: "Custom"
        )
    }
    
    static let presets: [DateRange] = [.sixMonths, .oneYear, .twoYears]
    
    func contains(_ date: Date) -> Bool {
        return date >= startDate && date <= endDate
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

public enum MetricType: String, CaseIterable, Codable {
    case maxWeight
    case totalVolume
    case totalSessions
    case totalReps

    public var displayName: String {
        switch self {
        case .maxWeight:
            return "Max Weight"
        case .totalVolume:
            return "Total Volume"
        case .totalSessions:
            return "Total Sets"
        case .totalReps:
            return "Total Reps"
        }
    }

    public var unit: String {
        switch self {
        case .maxWeight, .totalVolume:
            return "lbs"
        case .totalSessions:
            return "sets"
        case .totalReps:
            return "reps"
        }
    }
} 