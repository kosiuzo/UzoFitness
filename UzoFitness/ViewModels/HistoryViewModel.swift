import Foundation
import SwiftData
import SwiftUI
import UzoFitnessCore

@MainActor
class HistoryViewModel: ObservableObject {
    // MARK: - Published State
    @Published var allWorkoutSessions: [WorkoutSession] = []
    @Published var selectedDate: Date?
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    // MARK: - Computed Properties
    var sessionsForSelectedDate: [WorkoutSession] {
        guard let selectedDate = selectedDate else { return [] }
        return allWorkoutSessions.filter { 
            calendar.isDate($0.date, inSameDayAs: selectedDate)
        }
    }
    
    var workoutDates: Set<Date> {
        ProgressAnalysisLogic.getWorkoutDates(from: allWorkoutSessions)
    }
    
    var streakCount: Int {
        ProgressAnalysisLogic.calculateWorkoutStreak(from: allWorkoutSessions)
    }
    
    var totalWorkoutDays: Int {
        ProgressAnalysisLogic.calculateTotalWorkoutDays(from: allWorkoutSessions)
    }
    
    // MARK: - Properties
    var modelContext: ModelContext
    private let calendar = Calendar.current
    
    // MARK: - Initialization
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func selectDate(_ date: Date) {
        selectedDate = date
    }
    
    // MARK: - Data Loading
    func loadWorkoutSessions() async {
        isLoading = true
        error = nil
        
        do {
            let descriptor = FetchDescriptor<WorkoutSession>(
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            
            let sessions = try modelContext.fetch(descriptor)
            
            // Filter sessions that have actual exercise data
            allWorkoutSessions = sessions.filter { !$0.sessionExercises.isEmpty }
            
        } catch {
            self.error = "Failed to load workout data"
        }
        
        isLoading = false
    }
    
    // MARK: - Helper Methods
    func hasWorkoutData(for date: Date) -> Bool {
        return ProgressAnalysisLogic.hasWorkoutData(for: date, in: allWorkoutSessions)
    }
}

 