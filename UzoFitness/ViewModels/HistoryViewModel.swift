import Foundation
import SwiftData
import Combine
import SwiftUI

// MARK: - WorkoutSessionSummary Helper Struct
struct WorkoutSessionSummary: Identifiable, Hashable {
    let id: UUID
    let title: String
    let duration: TimeInterval?
    let totalVolume: Double
    let exerciseCount: Int
    let planName: String?
    let sessionDate: Date
    
    init(from session: WorkoutSession) {
        self.id = session.id
        self.title = session.title.isEmpty ? "Workout" : session.title
        self.duration = session.duration
        self.totalVolume = session.totalVolume
        self.exerciseCount = session.sessionExercises.count
        self.planName = session.plan?.customName
        self.sessionDate = session.date
    }
    
    var formattedDuration: String {
        guard let duration = duration else { return "N/A" }
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var formattedVolume: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: totalVolume)) ?? "0"
    }
}

@MainActor
class HistoryViewModel: ObservableObject {
    // MARK: - Published State
    @Published var calendarData: [Date: [WorkoutSessionSummary]] = [:]
    @Published var selectedDate: Date?
    @Published var dailyDetails: [PerformedExercise] = []
    @Published var error: Error?
    @Published var state: HistoryLoadingState = .idle
    @Published var isLoading: Bool = false
    
    // MARK: - Computed Properties
    var totalVolumeForDay: Double {
        guard let selectedDate = selectedDate,
              let sessions = calendarData[normalizeDate(selectedDate)] else {
            return 0.0
        }
        return sessions.reduce(0) { $0 + $1.totalVolume }
    }
    
    var longestSession: WorkoutSessionSummary? {
        guard let selectedDate = selectedDate,
              let sessions = calendarData[normalizeDate(selectedDate)] else {
            return nil
        }
        return sessions.max { (lhs, rhs) in
            let lhsDuration = lhs.duration ?? 0
            let rhsDuration = rhs.duration ?? 0
            return lhsDuration < rhsDuration
        }
    }
    
    var streakCount: Int {
        let sortedDates = calendarData.keys
            .filter { !calendarData[$0]!.isEmpty }
            .sorted(by: >)
        
        guard !sortedDates.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        for date in sortedDates {
            if calendar.isDate(date, inSameDayAs: currentDate) {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else if abs(calendar.dateComponents([.day], from: date, to: currentDate).day ?? 0) > 1 {
                // More than 1 day gap, break streak
                break
            }
        }
        
        return streak
    }
    
    var selectedDateSessions: [WorkoutSessionSummary] {
        guard let selectedDate = selectedDate else { return [] }
        return calendarData[normalizeDate(selectedDate)] ?? []
    }
    
    var totalWorkoutDays: Int {
        calendarData.filter { !$1.isEmpty }.count
    }
    
    var averageWorkoutDuration: TimeInterval? {
        let allSessions = calendarData.values.flatMap { $0 }
        let durationsWithValues = allSessions.compactMap { $0.duration }
        
        guard !durationsWithValues.isEmpty else { return nil }
        return durationsWithValues.reduce(0, +) / Double(durationsWithValues.count)
    }
    
    var totalVolume: Double {
        calendarData.values.flatMap { $0 }.reduce(0) { $0 + $1.totalVolume }
    }
    
    // MARK: - Private Properties
    private var modelContext: ModelContext
    private var cancellables = Set<AnyCancellable>()
    private let calendar = Calendar.current
    
    // MARK: - Initialization
    init() {
        // Initialize with empty context - will be set later
        let container = try! ModelContainer(for: WorkoutSession.self)
        self.modelContext = container.mainContext
        print("🔄 [HistoryViewModel.init] Initialized with temporary ModelContext")
    }
    
    func setModelContext(_ modelContext: ModelContext) {
        self.modelContext = modelContext
        print("🔄 [HistoryViewModel.setModelContext] Updated ModelContext")
        loadCalendarData()
    }
    
    func selectDate(_ date: Date) {
        print("🔄 [HistoryViewModel.selectDate] Selecting date: \(date)")
        
        let normalizedDate = normalizeDate(date)
        selectedDate = normalizedDate
        
        // Load detailed data for the selected date
        loadDailyDetails(for: normalizedDate)
        
        print("📊 [HistoryViewModel] Selected date: \(normalizedDate)")
    }
    
    // MARK: - Intent Handling
    func handleIntent(_ intent: HistoryIntent) {
        print("🔄 [HistoryViewModel.handleIntent] Processing intent: \(intent)")
        
        switch intent {
        case .selectDate(let date):
            selectDate(date)
            
        case .loadData:
            loadCalendarData()
            
        case .refreshData:
            refreshData()
            
        case .clearSelection:
            clearSelection()
            
        case .clearError:
            error = nil
        }
    }
    
    // MARK: - Date Selection (moved to public section)
    
    private func clearSelection() {
        print("🔄 [HistoryViewModel.clearSelection] Clearing date selection")
        selectedDate = nil
        dailyDetails = []
        print("📊 [HistoryViewModel] Selection cleared")
    }
    
    // MARK: - Data Loading
    private func loadCalendarData() {
        print("🔄 [HistoryViewModel.loadCalendarData] Starting calendar data load")
        state = .loading
        isLoading = true
        
        do {
            let descriptor = FetchDescriptor<WorkoutSession>(
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            
            let sessions = try modelContext.fetch(descriptor)
            
            // Group sessions by normalized date
            var groupedSessions: [Date: [WorkoutSessionSummary]] = [:]
            
            for session in sessions {
                let normalizedDate = normalizeDate(session.date)
                let summary = WorkoutSessionSummary(from: session)
                
                if groupedSessions[normalizedDate] != nil {
                    groupedSessions[normalizedDate]?.append(summary)
                } else {
                    groupedSessions[normalizedDate] = [summary]
                }
            }
            
            calendarData = groupedSessions
            
            print("✅ [HistoryViewModel.loadCalendarData] Successfully loaded \(sessions.count) sessions across \(groupedSessions.count) days")
            print("📊 [HistoryViewModel] State changed to: loaded")
            
            state = .loaded
            isLoading = false
            
        } catch {
            print("❌ [HistoryViewModel.loadCalendarData] Error: \(error.localizedDescription)")
            print("📊 [HistoryViewModel] State changed to: error")
            
            self.error = error
            state = .error
            isLoading = false
        }
    }
    
    private func loadDailyDetails(for date: Date) {
        print("🔄 [HistoryViewModel.loadDailyDetails] Loading details for date: \(date)")
        
        do {
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            let descriptor = FetchDescriptor<PerformedExercise>(
                predicate: #Predicate<PerformedExercise> { exercise in
                    exercise.performedAt >= startOfDay && exercise.performedAt < endOfDay
                },
                sortBy: [SortDescriptor(\.performedAt)]
            )
            
            dailyDetails = try modelContext.fetch(descriptor)
            
            print("📊 [HistoryViewModel.loadDailyDetails] Loaded \(dailyDetails.count) performed exercises for \(date)")
            
        } catch {
            print("❌ [HistoryViewModel.loadDailyDetails] Error: \(error.localizedDescription)")
            self.error = error
            dailyDetails = []
        }
    }
    
    private func refreshData() {
        print("🔄 [HistoryViewModel.refreshData] Refreshing all data")
        loadCalendarData()
        
        if let selectedDate = selectedDate {
            loadDailyDetails(for: selectedDate)
        }
    }
    
    // MARK: - Helper Methods
    private func normalizeDate(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }
    
    // MARK: - Analytics Methods
    func getWorkoutFrequency(for period: AnalyticsPeriod) -> [Date: Int] {
        let calendar = Calendar.current
        let now = Date()
        let startDate: Date
        
        switch period {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .threeMonths:
            startDate = calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }
        
        let filteredData = calendarData.filter { date, _ in
            date >= startDate && date <= now
        }
        
        return filteredData.mapValues { $0.count }
    }
    
    func getVolumeHistory(for period: AnalyticsPeriod) -> [Date: Double] {
        let calendar = Calendar.current
        let now = Date()
        let startDate: Date
        
        switch period {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .threeMonths:
            startDate = calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }
        
        let filteredData = calendarData.filter { date, _ in
            date >= startDate && date <= now
        }
        
        return filteredData.mapValues { sessions in
            sessions.reduce(0) { $0 + $1.totalVolume }
        }
    }
    
    func hasWorkoutData(for date: Date) -> Bool {
        let normalizedDate = normalizeDate(date)
        return !(calendarData[normalizedDate]?.isEmpty ?? true)
    }
    
    func getSessionCount(for date: Date) -> Int {
        let normalizedDate = normalizeDate(date)
        return calendarData[normalizedDate]?.count ?? 0
    }
}

// MARK: - Supporting Types

enum HistoryLoadingState {
    case idle
    case loading
    case loaded
    case error
}

enum HistoryIntent {
    case selectDate(Date)
    case loadData
    case refreshData
    case clearSelection
    case clearError
}

enum AnalyticsPeriod: CaseIterable {
    case week
    case month
    case threeMonths
    case year
    
    var displayName: String {
        switch self {
        case .week:
            return "Week"
        case .month:
            return "Month"
        case .threeMonths:
            return "3 Months"
        case .year:
            return "Year"
        }
    }
}



enum HistoryError: Error, LocalizedError, Equatable {
    case dataLoadFailed
    case dateSelectionFailed
    case noDataFound
    case invalidDateRange
    case custom(String)
    
    var errorDescription: String? {
        switch self {
        case .dataLoadFailed:
            return "Failed to load workout history data."
        case .dateSelectionFailed:
            return "Failed to select the requested date."
        case .noDataFound:
            return "No workout data found for the selected period."
        case .invalidDateRange:
            return "The selected date range is invalid."
        case .custom(let message):
            return message
        }
    }
} 