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
    
    // Session-runtime state
    @Attribute var currentSet: Int
    @Attribute var isCompleted: Bool
    @Attribute var restTimer: TimeInterval?
    @Attribute var createdAt: Date
    
    @Relationship var session: WorkoutSession?
    @Relationship var completedSets: [CompletedSet]

    var totalVolume: Double {
        completedSets.reduce(0) {
            $0 + (Double($1.reps) * $1.weight)
        }
    }

    init(
        id: UUID = UUID(),
        exercise: Exercise,
        plannedSets: Int,
        plannedReps: Int,
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
        self.plannedReps = plannedReps
        self.plannedWeight = plannedWeight
        self.position = position
        self.supersetID = supersetID
        self.currentSet = currentSet
        self.isCompleted = isCompleted
        self.restTimer = restTimer
        self.session = session
        self.createdAt = createdAt
        self.completedSets = []
    }
}
