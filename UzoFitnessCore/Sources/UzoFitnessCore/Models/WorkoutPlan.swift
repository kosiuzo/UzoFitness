import Foundation
import SwiftData

@Model
public final class WorkoutPlan: Identified, Timestamped, Codable {
    @Attribute(.unique) public var id: UUID
    @Attribute public var customName: String
    @Attribute public var isActive: Bool
    @Attribute public var startedAt: Date
    @Attribute public var durationWeeks: Int
    @Attribute public var createdAt: Date
    
    @Relationship public var template: WorkoutTemplate?

    public init(
        id: UUID = UUID(),
        customName: String,
        isActive: Bool = true,
        startedAt: Date = .now,
        durationWeeks: Int = 8,
        template: WorkoutTemplate? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.customName = customName
        self.isActive = isActive
        self.startedAt = startedAt
        self.durationWeeks = max(durationWeeks, 1)
        self.template = template
        self.createdAt = createdAt
    }

    // MARK: - Codable Implementation
    public enum CodingKeys: CodingKey {
        case id, customName, isActive, startedAt, durationWeeks, createdAt
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(customName, forKey: .customName)
        try container.encode(isActive, forKey: .isActive)
        try container.encode(startedAt, forKey: .startedAt)
        try container.encode(durationWeeks, forKey: .durationWeeks)
        try container.encode(createdAt, forKey: .createdAt)
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.customName = try container.decode(String.self, forKey: .customName)
        self.isActive = try container.decode(Bool.self, forKey: .isActive)
        self.startedAt = try container.decode(Date.self, forKey: .startedAt)
        self.durationWeeks = try container.decode(Int.self, forKey: .durationWeeks)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
}
