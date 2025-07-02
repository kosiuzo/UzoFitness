import Foundation
import OSLog
import SwiftData

@Model
final class CompletedSet: Identified {
    @Attribute(.unique) var id: UUID
    @Attribute var reps: Int
    @Attribute var weight: Double
    @Attribute var isCompleted: Bool
    @Attribute var position: Int // Add position to maintain order
    @Attribute var externalSampleUUID: UUID?
    
    @Relationship var sessionExercise: SessionExercise?

    init(
        id: UUID = UUID(),
        reps: Int,
        weight: Double,
        isCompleted: Bool = true,
        position: Int = 0,
        externalSampleUUID: UUID? = nil,
        sessionExercise: SessionExercise? = nil
    ) {
        self.id = id
        self.reps = reps
        self.weight = weight
        self.isCompleted = isCompleted
        self.position = position
        self.externalSampleUUID = externalSampleUUID
        self.sessionExercise = sessionExercise
        
        AppLogger.debug("[CompletedSet.init] Created set: \(reps) reps @ \(weight) lbs (completed: \(isCompleted), position: \(position))", category: "CompletedSet")
    }
}
