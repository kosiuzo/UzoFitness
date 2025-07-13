import Foundation
import SwiftData
import SwiftUI

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
        Set(allWorkoutSessions.map { calendar.startOfDay(for: $0.date) })
    }
    
    var streakCount: Int {
        let uniqueDates = workoutDates.sorted(by: >)
        guard !uniqueDates.isEmpty else { return 0 }
        
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        for date in uniqueDates {
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
        workoutDates.count
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
        return allWorkoutSessions.contains { 
            calendar.isDate($0.date, inSameDayAs: date)
        }
    }
}

 