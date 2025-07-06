import Foundation
import SwiftData

@Model
final class WorkoutSession: Identified, Timestamped {
    @Attribute(.unique) var id: UUID
    @Attribute var date: Date
    @Attribute var title: String
    @Attribute var duration: TimeInterval?
    @Attribute var createdAt: Date
    
    // Session state tracking for logging ViewModel
    @Attribute var currentExerciseID: UUID?
    @Attribute var currentSetNumber: Int
    @Attribute var isSupersetActive: Bool
    
    @Relationship var plan: WorkoutPlan?
    @Relationship(inverse: \SessionExercise.session) var sessionExercises: [SessionExercise]

    var totalVolume: Double {
        sessionExercises.reduce(0) { $0 + $1.totalVolume }
    }

    init(
        id: UUID = UUID(),
        date: Date,
        title: String = "",
        duration: TimeInterval? = nil,
        plan: WorkoutPlan? = nil,
        createdAt: Date = .now,
        currentExerciseID: UUID? = nil,
        currentSetNumber: Int = 0,
        isSupersetActive: Bool = false
    ) {
        self.id = id
        self.date = date
        self.title = title
        self.duration = duration
        self.plan = plan
        self.createdAt = createdAt
        self.currentExerciseID = currentExerciseID
        self.currentSetNumber = currentSetNumber
        self.isSupersetActive = isSupersetActive
        self.sessionExercises = []
    }
}
