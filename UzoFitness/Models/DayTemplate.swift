import Foundation
import SwiftData

@Model
final class DayTemplate: Identified {
    @Attribute(.unique) var id: UUID
    @Attribute var weekday: Weekday
    @Attribute var isRest: Bool
    @Attribute var notes: String
    
    @Relationship var workoutTemplate: WorkoutTemplate?
    @Relationship var exerciseTemplates: [ExerciseTemplate]

    init(
        id: UUID = UUID(),
        weekday: Weekday,
        isRest: Bool = false,
        notes: String = "",
        workoutTemplate: WorkoutTemplate? = nil
    ) {
        self.id = id
        self.weekday = weekday
        self.isRest = isRest
        self.notes = notes
        self.workoutTemplate = workoutTemplate
        self.exerciseTemplates = []
    }
}
