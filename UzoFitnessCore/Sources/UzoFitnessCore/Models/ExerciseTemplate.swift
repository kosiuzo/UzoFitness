import Foundation
import SwiftData

@Model
public final class ExerciseTemplate: Identified, Timestamped, Codable {
    @Attribute(.unique) public var id: UUID
    @Relationship public var exercise: Exercise
    
    @Attribute public var setCount: Int
    @Attribute public var reps: Int
    @Attribute public var weight: Double?
    @Attribute public var position: Double
    @Attribute public var supersetID: UUID?
    @Attribute public var createdAt: Date
    
    @Relationship public var dayTemplate: DayTemplate?

    public init(
        id: UUID = UUID(),
        exercise: Exercise,
        setCount: Int,
        reps: Int,
        weight: Double? = nil,
        position: Double,
        supersetID: UUID? = nil,
        dayTemplate: DayTemplate? = nil,
        createdAt: Date = .now
        
    ) {
        self.id = id
        self.exercise = exercise
        self.setCount = setCount
        self.reps = reps
        self.weight = weight
        self.position = position
        self.supersetID = supersetID
        self.dayTemplate = dayTemplate
        self.createdAt = createdAt
    }

    // MARK: - Codable Implementation
    public enum CodingKeys: CodingKey {
        case id, setCount, reps, weight, position, supersetID, createdAt
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(setCount, forKey: .setCount)
        try container.encode(reps, forKey: .reps)
        try container.encode(weight, forKey: .weight)
        try container.encode(position, forKey: .position)
        try container.encode(supersetID, forKey: .supersetID)
        try container.encode(createdAt, forKey: .createdAt)
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.setCount = try container.decode(Int.self, forKey: .setCount)
        self.reps = try container.decode(Int.self, forKey: .reps)
        self.weight = try container.decodeIfPresent(Double.self, forKey: .weight)
        self.position = try container.decode(Double.self, forKey: .position)
        self.supersetID = try container.decodeIfPresent(UUID.self, forKey: .supersetID)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.exercise = Exercise(id: UUID(), name: "", category: .strength)
        self.dayTemplate = nil
    }
}





