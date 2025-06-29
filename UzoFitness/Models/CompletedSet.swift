import Foundation
import SwiftData

@Model
final class CompletedSet: Identified {
    @Attribute(.unique) var id: UUID
    @Attribute var reps: Int
    @Attribute var weight: Double
    @Attribute var isCompleted: Bool
    @Attribute var externalSampleUUID: UUID?
    
    @Relationship var sessionExercise: SessionExercise?

    init(
        id: UUID = UUID(),
        reps: Int,
        weight: Double,
        isCompleted: Bool = true,
        externalSampleUUID: UUID? = nil,
        sessionExercise: SessionExercise? = nil
    ) {
        self.id = id
        self.reps = reps
        self.weight = weight
        self.isCompleted = isCompleted
        self.externalSampleUUID = externalSampleUUID
        self.sessionExercise = sessionExercise
        sessionExercise?.completedSets.append(self)
        
        print("🏃‍♂️ [CompletedSet.init] Created set: \(reps) reps @ \(weight) lbs (completed: \(isCompleted))")
    }
}
