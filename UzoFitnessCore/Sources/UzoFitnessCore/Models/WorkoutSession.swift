import Foundation
import SwiftData

@Model
public final class WorkoutSession: Identified, Timestamped, Codable {
    @Attribute(.unique) public var id: UUID
    @Attribute public var date: Date
    @Attribute public var title: String
    @Attribute public var duration: TimeInterval?
    @Attribute public var createdAt: Date
    
    @Relationship public var plan: WorkoutPlan?
    @Relationship(inverse: \SessionExercise.session) public var sessionExercises: [SessionExercise]

    public var totalVolume: Double {
        sessionExercises.reduce(0) { $0 + $1.totalVolume }
    }

    public init(
        id: UUID = UUID(),
        date: Date,
        title: String = "",
        duration: TimeInterval? = nil,
        plan: WorkoutPlan? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.date = date
        self.title = title
        self.duration = duration
        self.plan = plan
        self.createdAt = createdAt
        self.sessionExercises = []
    }

    // MARK: - Codable Implementation
    public enum CodingKeys: CodingKey {
        case id, date, title, duration, createdAt
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(title, forKey: .title)
        try container.encode(duration, forKey: .duration)
        try container.encode(createdAt, forKey: .createdAt)
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.date = try container.decode(Date.self, forKey: .date)
        self.title = try container.decode(String.self, forKey: .title)
        self.duration = try container.decodeIfPresent(TimeInterval.self, forKey: .duration)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.plan = nil
        self.sessionExercises = []
    }
}
