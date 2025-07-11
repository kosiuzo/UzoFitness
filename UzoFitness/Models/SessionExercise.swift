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
        createdAt: Date = .now
    ) {
        self.id = id
        self.exercise = exercise
        self.plannedSets = plannedSets
        self.plannedReps = plannedReps ?? 10
        self.plannedWeight = plannedWeight
        self.position = position
        self.supersetID = supersetID
        self.currentSet = currentSet
        self.isCompleted = isCompleted
        self.restTimer = restTimer
        self.session = session
        self.createdAt = createdAt
        self.completedSets = []
        self.previousTotalVolume = nil
        self.previousSessionDate = nil
        
        AppLogger.debug("[SessionExercise.init] Created session exercise for: \(exercise.name)", category: "SessionExercise")
    }
    
    /// Gets the last used reps and weight from the most recent completed set
    var lastUsedValues: (weight: Double?, reps: Int?) {
        guard let lastCompletedSet = completedSets.filter({ $0.isCompleted }).last else {
            return (nil, nil)
        }
        return (lastCompletedSet.weight, lastCompletedSet.reps)
    }
    
    /// Updates all incomplete sets with the last used values
    func updateAllSetsWithLastUsedValues() {
        let lastUsed = lastUsedValues
        guard let weight = lastUsed.weight, let reps = lastUsed.reps else {
            AppLogger.debug("[SessionExercise.updateAllSetsWithLastUsedValues] No last used values available for: \(exercise.name)", category: "SessionExercise")
            return
        }
        
        for set in completedSets.filter({ !$0.isCompleted }) {
            set.weight = weight
            set.reps = reps
        }
        
        AppLogger.info("[SessionExercise.updateAllSetsWithLastUsedValues] Updated all incomplete sets with weight: \(weight), reps: \(reps) for: \(exercise.name)", category: "SessionExercise")
    }
}
