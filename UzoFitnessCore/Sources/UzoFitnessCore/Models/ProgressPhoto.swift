import Foundation
import SwiftData

@Model
public final class ProgressPhoto: Identified, Timestamped, Codable {
    @Attribute(.unique) public var id: UUID
    @Attribute public var date: Date
    @Attribute public var angle: PhotoAngle
    @Attribute public var assetIdentifier: String
    @Attribute public var weightSampleUUID: UUID?
    @Attribute public var notes: String
    /// Optional manual weight annotation (lbs) set by the user
    @Attribute public var manualWeight: Double?
    @Attribute public var createdAt: Date

    public init(
        id: UUID = UUID(),
        date: Date,
        angle: PhotoAngle,
        assetIdentifier: String,
        weightSampleUUID: UUID? = nil,
        notes: String = "",
        manualWeight: Double? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.date = date
        self.angle = angle
        self.assetIdentifier = assetIdentifier
        self.weightSampleUUID = weightSampleUUID
        self.notes = notes
        self.manualWeight = manualWeight
        self.createdAt = createdAt
    }

    // MARK: - Codable Implementation
    public enum CodingKeys: CodingKey {
        case id, date, angle, assetIdentifier, weightSampleUUID, notes, manualWeight, createdAt
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(angle, forKey: .angle)
        try container.encode(assetIdentifier, forKey: .assetIdentifier)
        try container.encodeIfPresent(weightSampleUUID, forKey: .weightSampleUUID)
        try container.encode(notes, forKey: .notes)
        try container.encodeIfPresent(manualWeight, forKey: .manualWeight)
        try container.encode(createdAt, forKey: .createdAt)
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.date = try container.decode(Date.self, forKey: .date)
        self.angle = try container.decode(PhotoAngle.self, forKey: .angle)
        self.assetIdentifier = try container.decode(String.self, forKey: .assetIdentifier)
        self.weightSampleUUID = try container.decodeIfPresent(UUID.self, forKey: .weightSampleUUID)
        self.notes = try container.decode(String.self, forKey: .notes)
        self.manualWeight = try container.decodeIfPresent(Double.self, forKey: .manualWeight)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
}
