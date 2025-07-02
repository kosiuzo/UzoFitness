import Foundation
import SwiftData

@Model
final class Exercise: Identified, Codable {
    // MARK: Stored
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var name: String
    @Attribute var category: ExerciseCategory
    @Attribute var instructions: String
    @Attribute var mediaAssetID: String?
    
    // MARK: - Cached Last Used Values
    @Attribute var lastUsedWeight: Double?
    @Attribute var lastUsedReps: Int?
    @Attribute var lastTotalVolume: Double?
    @Attribute var lastUsedDate: Date?
    
    // MARK: Relationships
    @Relationship var completedSets: [CompletedSet]
    @Relationship var performedRecords: [PerformedExercise] = []

    // MARK: Init
    init(
        id: UUID = UUID(),
        name: String,
        category: ExerciseCategory,
        instructions: String = "",
        mediaAssetID: String? = nil,
        lastUsedWeight: Double? = nil,
        lastUsedReps: Int? = nil,
        lastTotalVolume: Double? = nil,
        lastUsedDate: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.instructions = instructions
        self.mediaAssetID = mediaAssetID
        self.lastUsedWeight = lastUsedWeight
        self.lastUsedReps = lastUsedReps
        self.lastTotalVolume = lastTotalVolume
        self.lastUsedDate = lastUsedDate
        self.completedSets = []
        AppLogger.debug("[Exercise.init] Created exercise: \(name)", category: "Exercise")
    }
    
    // MARK: - Codable Implementation
    enum CodingKeys: CodingKey {
        case id, name, category, instructions, mediaAssetID
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(category, forKey: .category)
        try container.encode(instructions, forKey: .instructions)
        try container.encodeIfPresent(mediaAssetID, forKey: .mediaAssetID)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Handle missing ID by generating a new UUID
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.category = try container.decode(ExerciseCategory.self, forKey: .category)
        self.instructions = try container.decode(String.self, forKey: .instructions)
        self.mediaAssetID = try container.decodeIfPresent(String.self, forKey: .mediaAssetID)
        self.lastUsedWeight = nil
        self.lastUsedReps = nil
        self.lastTotalVolume = nil
        self.lastUsedDate = nil
        self.completedSets = []
        self.performedRecords = []
        AppLogger.debug("[Exercise.init] Decoded exercise: \(name)", category: "Exercise")
    }
}


