import Foundation
import SwiftData
import Combine
import SwiftUI

@MainActor
class HistoryViewModel: ObservableObject {
    // MARK: - Published State
    @Published var workoutSessions: [WorkoutSession] = []
    @Published var selectedDate: Date?
    @Published var error: Error?
    @Published var state: HistoryLoadingState = .idle
    @Published var isLoading: Bool = false
    
    // MARK: - Computed Properties
    var streakCount: Int {
        let workoutDates = Set(workoutSessions.map { calendar.startOfDay(for: $0.date) })
        let sortedDates = workoutDates.sorted(by: >)
        
        guard !sortedDates.isEmpty else { return 0 }
        
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        for date in sortedDates {
            if calendar.isDate(date, inSameDayAs: currentDate) {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else if abs(calendar.dateComponents([.day], from: date, to: currentDate).day ?? 0) > 1 {
                break
            }
        }
        
        return streak
    }
    
    var totalWorkoutDays: Int {
        Set(workoutSessions.map { calendar.startOfDay(for: $0.date) }).count
    }
    
    var workoutDates: Set<Date> {
        Set(workoutSessions.map { calendar.startOfDay(for: $0.date) })
    }
    
    func sessionsForDate(_ date: Date) -> [WorkoutSession] {
        workoutSessions.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }
    
    // MARK: - Private Properties
    private var modelContext: ModelContext
    private var cancellables = Set<AnyCancellable>()
    private let calendar = Calendar.current
    
    // MARK: - Initialization
    init() {
        do {
            let container = try ModelContainer(for: WorkoutSession.self)
            self.modelContext = container.mainContext
            AppLogger.debug("[HistoryViewModel.init] Initialized with temporary ModelContext", category: "HistoryViewModel")
        } catch {
            AppLogger.error("[HistoryViewModel.init] Failed to create ModelContainer: \(error.localizedDescription)", category: "HistoryViewModel", error: error)
            self.error = error
            self.state = .error

            let fallbackConfig = ModelConfiguration(isStoredInMemoryOnly: true)
            if let fallback = try? ModelContainer(for: WorkoutSession.self, configurations: fallbackConfig) {
                self.modelContext = fallback.mainContext
                AppLogger.debug("[HistoryViewModel.init] Initialized with in-memory fallback context", category: "HistoryViewModel")
            } else {
                self.modelContext = PersistenceController.shared.context
            }
        }
    }
    
    func setModelContext(_ modelContext: ModelContext) {
        self.modelContext = modelContext
        AppLogger.debug("[HistoryViewModel.setModelContext] Updated ModelContext", category: "HistoryViewModel")
        loadWorkoutData()
    }
    
    func selectDate(_ date: Date) {
        AppLogger.debug("[HistoryViewModel.selectDate] Selecting date: \(date)", category: "HistoryViewModel")
        selectedDate = calendar.startOfDay(for: date)
        AppLogger.debug("[HistoryViewModel] Selected date: \(selectedDate ?? Date())", category: "HistoryViewModel")
    }
    
    // MARK: - Intent Handling
    func handleIntent(_ intent: HistoryIntent) {
        AppLogger.debug("[HistoryViewModel.handleIntent] Processing intent: \(intent)", category: "HistoryViewModel")
        
        switch intent {
        case .selectDate(let date):
            selectDate(date)
            
        case .loadData:
            loadWorkoutData()
            
        case .refreshData:
            refreshData()
            
        case .clearSelection:
            clearSelection()
            
        case .clearError:
            error = nil
        }
    }
    
    private func clearSelection() {
        AppLogger.debug("[HistoryViewModel.clearSelection] Clearing date selection", category: "HistoryViewModel")
        selectedDate = nil
        AppLogger.debug("[HistoryViewModel] Selection cleared", category: "HistoryViewModel")
    }
    
    // MARK: - Data Loading
    private func loadWorkoutData() {
        AppLogger.debug("[HistoryViewModel.loadWorkoutData] Starting workout data load", category: "HistoryViewModel")
        state = .loading
        isLoading = true
        
        do {
            let descriptor = FetchDescriptor<WorkoutSession>(
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            
            let sessions = try modelContext.fetch(descriptor)
            
            // Show all workout sessions without filtering
            workoutSessions = sessions
            
            AppLogger.info("[HistoryViewModel.loadWorkoutData] Successfully loaded \(workoutSessions.count) sessions", category: "HistoryViewModel")
            AppLogger.debug("[HistoryViewModel] State changed to: loaded", category: "HistoryViewModel")
            
            state = .loaded
            isLoading = false
            
        } catch {
            AppLogger.error("[HistoryViewModel.loadWorkoutData] Error: \(error.localizedDescription)", category: "HistoryViewModel", error: error)
            AppLogger.debug("[HistoryViewModel] State changed to: error", category: "HistoryViewModel")
            
            self.error = error
            state = .error
            isLoading = false
        }
    }
    
    private func refreshData() {
        AppLogger.debug("[HistoryViewModel.refreshData] Refreshing all data", category: "HistoryViewModel")
        loadWorkoutData()
    }
    
    // MARK: - Helper Methods
    func hasWorkoutData(for date: Date) -> Bool {
        let normalizedDate = calendar.startOfDay(for: date)
        return workoutSessions.contains { calendar.isDate($0.date, inSameDayAs: normalizedDate) }
    }
    
    func getSessionCount(for date: Date) -> Int {
        sessionsForDate(date).count
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