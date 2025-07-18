import Foundation
import SwiftData

@Model
public final class DayTemplate: Identified, Codable {
    @Attribute(.unique) public var id: UUID
    @Attribute public var weekday: Weekday
    @Attribute public var isRest: Bool
    @Attribute public var notes: String
    
    @Relationship public var workoutTemplate: WorkoutTemplate?
    @Relationship public var exerciseTemplates: [ExerciseTemplate]

    public init(
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

    // MARK: - Codable Implementation
    public enum CodingKeys: CodingKey {
        case id, weekday, isRest, notes
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(weekday, forKey: .weekday)
        try container.encode(isRest, forKey: .isRest)
        try container.encode(notes, forKey: .notes)
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.weekday = try container.decode(Weekday.self, forKey: .weekday)
        self.isRest = try container.decode(Bool.self, forKey: .isRest)
        self.notes = try container.decode(String.self, forKey: .notes)
        self.workoutTemplate = nil
        self.exerciseTemplates = []
    }
}
