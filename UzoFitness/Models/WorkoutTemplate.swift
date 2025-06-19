import Foundation
import SwiftData

@Model
final class WorkoutTemplate: Identified, Timestamped {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var name: String
    @Attribute var summary: String
    @Attribute var createdAt: Date
    
    @Relationship var dayTemplates: [DayTemplate]
    @Relationship(inverse: \WorkoutPlan.template) var plans: [WorkoutPlan] = []

    init(
        id: UUID = UUID(),
        name: String,
        summary: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.summary = summary
        self.createdAt = createdAt
        self.dayTemplates = []
        self.plans = []
    }
}

