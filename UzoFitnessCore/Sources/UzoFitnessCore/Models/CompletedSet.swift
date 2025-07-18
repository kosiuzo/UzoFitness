import Foundation
import OSLog
import SwiftData

@Model
public final class CompletedSet: Identified, Codable {
    @Attribute(.unique) public var id: UUID
    @Attribute public var reps: Int
    @Attribute public var weight: Double
    @Attribute public var isCompleted: Bool
    @Attribute public var position: Int // Add position to maintain order
    @Attribute public var externalSampleUUID: UUID?
    
    @Relationship public var sessionExercise: SessionExercise?

    public init(
        id: UUID = UUID(),
        reps: Int,
        weight: Double,
        isCompleted: Bool = true,
        position: Int = 0,
        externalSampleUUID: UUID? = nil,
        sessionExercise: SessionExercise? = nil
    ) {
        self.id = id
        self.reps = reps
        self.weight = weight
        self.isCompleted = isCompleted
        self.position = position
        self.externalSampleUUID = externalSampleUUID
        self.sessionExercise = sessionExercise
        
        AppLogger.debug("[CompletedSet.init] Created set: \(reps) reps @ \(weight) lbs (completed: \(isCompleted), position: \(position))", category: "CompletedSet")
    }

    // MARK: - Codable Implementation
    public enum CodingKeys: CodingKey {
        case id, reps, weight, isCompleted, position, externalSampleUUID
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(reps, forKey: .reps)
        try container.encode(weight, forKey: .weight)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encode(position, forKey: .position)
        try container.encodeIfPresent(externalSampleUUID, forKey: .externalSampleUUID)
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.reps = try container.decode(Int.self, forKey: .reps)
        self.weight = try container.decode(Double.self, forKey: .weight)
        self.isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        self.position = try container.decode(Int.self, forKey: .position)
        self.externalSampleUUID = try container.decodeIfPresent(UUID.self, forKey: .externalSampleUUID)
        self.sessionExercise = nil
    }
}
