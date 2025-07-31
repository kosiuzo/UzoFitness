import Foundation
import SwiftData

@Model
final class WorkoutPlan: Identified, Timestamped {
    @Attribute(.unique) var id: UUID
    @Attribute var customName: String
    @Attribute var isActive: Bool
    @Attribute var startedAt: Date
    @Attribute var durationWeeks: Int
    @Attribute var createdAt: Date
    @Attribute var notes: String
    @Attribute var endedAt: Date?
    
    @Relationship var template: WorkoutTemplate?

    init(
        id: UUID = UUID(),
        customName: String,
        isActive: Bool = true,
        startedAt: Date = .now,
        durationWeeks: Int = 8,
        template: WorkoutTemplate? = nil,
        createdAt: Date = .now,
        notes: String = "",
        endedAt: Date? = nil
    ) {
        self.id = id
        self.customName = customName
        self.isActive = isActive
        self.startedAt = startedAt
        self.durationWeeks = max(durationWeeks, 1)
        self.template = template
        self.createdAt = createdAt
        self.notes = notes
        self.endedAt = endedAt
    }
}
