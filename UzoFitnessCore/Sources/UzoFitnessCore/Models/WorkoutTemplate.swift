import Foundation
import SwiftData

@Model
public final class WorkoutTemplate: Identified, Timestamped {
    @Attribute(.unique) public var id: UUID
    @Attribute(.unique) public var name: String
    @Attribute public var summary: String
    @Attribute public var createdAt: Date
    
    @Relationship public var dayTemplates: [DayTemplate]
    @Relationship(inverse: \WorkoutPlan.template) public var plans: [WorkoutPlan] = []

    public init(
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

