import Foundation
import SwiftData

@Model
final class CompletedSet: Identified {
    @Attribute(.unique) var id: UUID
    @Attribute var reps: Int
    @Attribute var weight: Double
    @Attribute var externalSampleUUID: UUID?
    
    @Relationship var sessionExercise: SessionExercise?

    init(
        id: UUID = UUID(),
        reps: Int,
        weight: Double,
        externalSampleUUID: UUID? = nil,
        sessionExercise: SessionExercise? = nil
    ) {
        self.id = id
        self.reps = reps
        self.weight = weight
        self.externalSampleUUID = externalSampleUUID
        self.sessionExercise = sessionExercise
    }
}
