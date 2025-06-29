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
        completedSets.reduce(0) {
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
            
            print("🏃‍♂️ [SessionExercise.init] Auto-populated from exercise: \(exercise.name)")
            print("📊 [SessionExercise.init] Suggested weight: \(suggestedValues.weight ?? 0), reps: \(suggestedValues.reps ?? 0)")
        } else {
            self.plannedReps = plannedReps ?? 10
            self.plannedWeight = plannedWeight
            self.previousTotalVolume = nil
            self.previousSessionDate = nil
            
            print("🔄 [SessionExercise.init] Created without auto-population for: \(exercise.name)")
        }
    }
    
    /// Updates the exercise's cached values when this session is completed
    func updateExerciseCacheOnCompletion() {
        guard isCompleted && !completedSets.isEmpty else {
            print("📊 [SessionExercise.updateExerciseCacheOnCompletion] Cannot update - not completed or no sets")
            return
        }
        
        print("🔄 [SessionExercise.updateExerciseCacheOnCompletion] Updating exercise cache for: \(exercise.name)")
        
        // Update exercise's cached values with this session's data
        let totalVolume = self.totalVolume
        
        if let lastSet = completedSets.last {
            exercise.lastUsedWeight = lastSet.weight
            exercise.lastUsedReps = lastSet.reps
        }
        
        exercise.lastTotalVolume = totalVolume
        exercise.lastUsedDate = session?.date ?? createdAt
        
        print("✅ [SessionExercise.updateExerciseCacheOnCompletion] Updated cache - Weight: \(exercise.lastUsedWeight ?? 0), Reps: \(exercise.lastUsedReps ?? 0), Volume: \(exercise.lastTotalVolume ?? 0)")
    }
}
