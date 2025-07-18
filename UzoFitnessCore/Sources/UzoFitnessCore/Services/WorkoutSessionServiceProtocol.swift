import Foundation
import Combine

/// Protocol for workout session management service
public protocol WorkoutSessionServiceProtocol {
    /// Current active workout session
    var currentSession: WorkoutSessionDTO? { get }
    
    /// Publisher for workout session updates
    var sessionUpdates: AnyPublisher<WorkoutSessionDTO?, Never> { get }
    
    /// Start a new workout session
    func startSession(for date: Date, title: String) async throws -> WorkoutSessionDTO
    
    /// Complete the current workout session
    func completeSession() async throws
    
    /// Add a completed set to an exercise
    func addCompletedSet(exerciseID: UUID, reps: Int, weight: Double) async throws
    
    /// Start rest timer for an exercise
    func startRestTimer(exerciseID: UUID, duration: TimeInterval) async throws
    
    /// Stop rest timer for an exercise
    func stopRestTimer(exerciseID: UUID) async throws
    
    /// Mark exercise as completed
    func completeExercise(exerciseID: UUID) async throws
    
    /// Get current exercise in session
    func getCurrentExercise() -> SessionExerciseDTO?
    
    /// Get current superset exercises
    func getCurrentSuperset() -> [SessionExerciseDTO]?
    
    /// Get today's workout plan
    func getTodaysWorkout() -> WorkoutSessionDTO?
    
    /// Check if today is a rest day
    func isRestDay() -> Bool
}