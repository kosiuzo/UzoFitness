import Foundation
import SwiftData

@Model
public final class SessionExercise: Identified, Timestamped, Codable {
    @Attribute(.unique) public var id: UUID
    @Relationship public var exercise: Exercise
    
    @Attribute public var plannedSets: Int
    @Attribute public var plannedReps: Int
    @Attribute public var plannedWeight: Double?
    @Attribute public var position: Double
    @Attribute public var supersetID: UUID?
    
    // Previous session data for comparison
    @Attribute public var previousTotalVolume: Double?
    @Attribute public var previousSessionDate: Date?
    
    // Session-runtime state
    @Attribute public var currentSet: Int
    @Attribute public var isCompleted: Bool
    @Attribute public var restTimer: TimeInterval?
    @Attribute public var createdAt: Date
    
    @Relationship public var session: WorkoutSession?
    @Relationship(inverse: \CompletedSet.sessionExercise) public var completedSets: [CompletedSet]

    public var totalVolume: Double {
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

    public init(
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
            
            AppLogger.debug("[SessionExercise.init] Auto-populated from exercise: \(exercise.name)", category: "SessionExercise")
            AppLogger.debug("[SessionExercise.init] Suggested weight: \(suggestedValues.weight ?? 0), reps: \(suggestedValues.reps ?? 0)", category: "SessionExercise")
        } else {
            self.plannedReps = plannedReps ?? 10
            self.plannedWeight = plannedWeight
            self.previousTotalVolume = nil
            self.previousSessionDate = nil
            
            AppLogger.debug("[SessionExercise.init] Created without auto-population for: \(exercise.name)", category: "SessionExercise")
        }
    }
    
    /// Updates the exercise's cached values when this session is completed
    public func updateExerciseCacheOnCompletion() {
        guard isCompleted && !completedSets.isEmpty else {
            AppLogger.debug("[SessionExercise.updateExerciseCacheOnCompletion] Cannot update - not completed or no sets", category: "SessionExercise")
            return
        }
        
        AppLogger.debug("[SessionExercise.updateExerciseCacheOnCompletion] Updating exercise cache for: \(exercise.name)", category: "SessionExercise")
        
        // Update exercise's cached values with this session's data
        let totalVolume = self.totalVolume
        
        if let lastSet = completedSets.last {
            exercise.lastUsedWeight = lastSet.weight
            exercise.lastUsedReps = lastSet.reps
        }
        
        exercise.lastTotalVolume = totalVolume
        exercise.lastUsedDate = session?.date ?? createdAt
        
        AppLogger.info("[SessionExercise.updateExerciseCacheOnCompletion] Updated cache - Weight: \(exercise.lastUsedWeight ?? 0), Reps: \(exercise.lastUsedReps ?? 0), Volume: \(exercise.lastTotalVolume ?? 0)", category: "SessionExercise")
    }
    
    // MARK: - Codable Implementation
    enum CodingKeys: CodingKey {
        case id, plannedSets, plannedReps, plannedWeight, position, supersetID, previousTotalVolume, previousSessionDate, currentSet, isCompleted, restTimer, createdAt
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(plannedSets, forKey: .plannedSets)
        try container.encode(plannedReps, forKey: .plannedReps)
        try container.encode(plannedWeight, forKey: .plannedWeight)
        try container.encode(position, forKey: .position)
        try container.encode(supersetID, forKey: .supersetID)
        try container.encode(previousTotalVolume, forKey: .previousTotalVolume)
        try container.encode(previousSessionDate, forKey: .previousSessionDate)
        try container.encode(currentSet, forKey: .currentSet)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encode(restTimer, forKey: .restTimer)
        try container.encode(createdAt, forKey: .createdAt)
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.plannedSets = try container.decode(Int.self, forKey: .plannedSets)
        self.plannedReps = try container.decode(Int.self, forKey: .plannedReps)
        self.plannedWeight = try container.decodeIfPresent(Double.self, forKey: .plannedWeight)
        self.position = try container.decode(Double.self, forKey: .position)
        self.supersetID = try container.decodeIfPresent(UUID.self, forKey: .supersetID)
        self.previousTotalVolume = try container.decodeIfPresent(Double.self, forKey: .previousTotalVolume)
        self.previousSessionDate = try container.decodeIfPresent(Date.self, forKey: .previousSessionDate)
        self.currentSet = try container.decode(Int.self, forKey: .currentSet)
        self.isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        self.restTimer = try container.decodeIfPresent(TimeInterval.self, forKey: .restTimer)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.exercise = Exercise(id: UUID(), name: "", category: .strength) // Placeholder, should be set after decoding
        self.session = nil
        self.completedSets = []
    }
}
