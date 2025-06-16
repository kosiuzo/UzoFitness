import Foundation
import SwiftData

@Model
final class ExerciseTemplate: Identified {
    @Attribute(.unique) var id: UUID
    @Relationship var exercise: Exercise
    
    @Attribute var setCount: Int
    @Attribute var reps: Int
    @Attribute var weight: Double?
    @Attribute var position: Double
    @Attribute var supersetID: UUID?
    
    @Relationship var dayTemplate: DayTemplate?

    init(
        id: UUID = UUID(),
        exercise: Exercise,
        setCount: Int,
        reps: Int,
        weight: Double? = nil,
        position: Double,
        supersetID: UUID? = nil,
        dayTemplate: DayTemplate? = nil
    ) {
        self.id = id
        self.exercise = exercise
        self.setCount = setCount
        self.reps = reps
        self.weight = weight
        self.position = position
        self.supersetID = supersetID
        self.dayTemplate = dayTemplate
    }
}
