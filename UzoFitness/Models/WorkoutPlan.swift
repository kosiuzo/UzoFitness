import Foundation
import SwiftData

@Model
final class WorkoutPlan: Identified, Timestamped {
    @Attribute(.unique) var id: UUID
    @Attribute var customName: String
    @Attribute var isActive: Bool
    @Attribute var startedAt: Date
    @Attribute var createdAt: Date
    
    @Relationship var template: WorkoutTemplate?

    init(
        id: UUID = UUID(),
        customName: String,
        isActive: Bool = true,
        startedAt: Date = .now,
        template: WorkoutTemplate? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.customName = customName
        self.isActive = isActive
        self.startedAt = startedAt
        self.template = template
        self.createdAt = createdAt
    }
}
