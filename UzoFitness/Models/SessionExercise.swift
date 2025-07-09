import Foundation
import SwiftData

@Model
final class SessionExercise: Identified, Timestamped {
    @Attribute(.unique) var id: UUID
    @Relationship var exercise: Exercise
    
    @Attribute var plannedSets: Int
    @Attribute var plannedReps: Int
    @Attribute var plannedWeight: Double?
    @Attribute var position: Double
    @Attribute var supersetID: UUID?
    
    // Previous session data for comparison
    @Attribute var previousTotalVolume: Double?
    @Attribute var previousSessionDate: Date?
    
    // Session-runtime state
    @Attribute var currentSet: Int
    @Attribute var isCompleted: Bool
    @Attribute var restTimer: TimeInterval?
    @Attribute var createdAt: Date
    
    @Relationship var session: WorkoutSession?
    @Relationship(inverse: \CompletedSet.sessionExercise) var completedSets: [CompletedSet]

    var totalVolume: Double {
        completedSets.filter { $0.isCompleted }.reduce(0) {
            $0 + (Double($1.reps) * $1.weight)
        }
    }
    
    /// Compares current total volume with previous session
    var volumeChange: Double? {
        guard let previousVolume = previousTotalVolume, previousVolume > 0 else { return nil }
        let currentVolume = totalVolume
        return currentVolume - previousVolume
    }
    
    /// Returns the percentage change in volume from previous session
    var volumeChangePercentage: Double? {
        guard let previousVolume = previousTotalVolume, previousVolume > 0 else { return nil }
        let currentVolume = totalVolume
        return ((currentVolume - previousVolume) / previousVolume) * 100
    }

    init(
        id: UUID = UUID(),
        exercise: Exercise,
        plannedSets: Int,
        plannedReps: Int? = nil,
        plannedWeight: Double? = nil,
        position: Double,
        supersetID: UUID? = nil,
        currentSet: Int = 0,
        isCompleted: Bool = false,
        restTimer: TimeInterval? = nil,
        session: WorkoutSession? = nil,
        createdAt: Date = .now,
        autoPopulateFromLastSession: Bool = true
    ) {
        self.id = id
        self.exercise = exercise
        self.plannedSets = plannedSets
        self.position = position
        self.supersetID = supersetID
        self.currentSet = currentSet
        self.isCompleted = isCompleted
        self.restTimer = restTimer
        self.session = session
        self.createdAt = createdAt
        self.completedSets = []
        
        // Auto-populate from exercise's cached values if requested
        if autoPopulateFromLastSession {
            let suggestedValues = exercise.suggestedStartingValues
            self.plannedReps = plannedReps ?? suggestedValues.reps ?? 10 // Default to 10 if no history
            self.plannedWeight = plannedWeight ?? suggestedValues.weight
            self.previousTotalVolume = suggestedValues.totalVolume
            self.previousSessionDate = exercise.lastUsedDate
            
            AppLogger.debug("[SessionExercise.init] Auto-populated from exercise: \(exercise.name) using CROSS-DAY data", category: "SessionExercise")
            AppLogger.debug("[SessionExercise.init] Exercise global cached values - Weight: \(exercise.lastUsedWeight ?? 0), Reps: \(exercise.lastUsedReps ?? 0), Last used: \(exercise.lastUsedDate?.description ?? "never")", category: "SessionExercise")
            AppLogger.debug("[SessionExercise.init] Final auto-populated values - Weight: \(self.plannedWeight ?? 0), Reps: \(self.plannedReps)", category: "SessionExercise")
        } else {
            self.plannedReps = plannedReps ?? 10
            self.plannedWeight = plannedWeight
            self.previousTotalVolume = nil
            self.previousSessionDate = nil
            
            AppLogger.debug("[SessionExercise.init] Created without auto-population for: \(exercise.name)", category: "SessionExercise")
        }
    }
    
    /// Updates the exercise's cached values when this session is completed
    /// This updates the global Exercise model so future sessions on ANY day will use these values
    func updateExerciseCacheOnCompletion() {
        guard isCompleted && !completedSets.isEmpty else {
            AppLogger.debug("[SessionExercise.updateExerciseCacheOnCompletion] Cannot update - not completed or no sets", category: "SessionExercise")
            return
        }
        
        AppLogger.debug("[SessionExercise.updateExerciseCacheOnCompletion] Updating GLOBAL exercise cache for: \(exercise.name) - will be used across all days", category: "SessionExercise")
        
        // Update exercise's cached values with this session's data
        let totalVolume = self.totalVolume
        
        // Find the best set for weight and reps (typically the last set or the heaviest set)
        let sortedSets = completedSets.filter { $0.isCompleted }.sorted { lhs, rhs in
            // Sort by weight first, then by position to get the heaviest completed set
            if lhs.weight != rhs.weight {
                return lhs.weight > rhs.weight
            }
            return lhs.position > rhs.position
        }
        
        if let bestSet = sortedSets.first {
            let oldWeight = exercise.lastUsedWeight
            let oldReps = exercise.lastUsedReps
            
            exercise.lastUsedWeight = bestSet.weight
            exercise.lastUsedReps = bestSet.reps
            
            AppLogger.info("[SessionExercise.updateExerciseCacheOnCompletion] Updated weight: \(oldWeight ?? 0) → \(bestSet.weight), reps: \(oldReps ?? 0) → \(bestSet.reps)", category: "SessionExercise")
        }
        
        exercise.lastTotalVolume = totalVolume
        exercise.lastUsedDate = session?.date ?? createdAt
        
        AppLogger.info("[SessionExercise.updateExerciseCacheOnCompletion] Updated GLOBAL cache for \(exercise.name) - Weight: \(exercise.lastUsedWeight ?? 0), Reps: \(exercise.lastUsedReps ?? 0) - will be used on ANY day this exercise appears", category: "SessionExercise")
    }
}
