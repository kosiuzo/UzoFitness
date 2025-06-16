import Foundation
import SwiftData

@Model
final class Exercise: Identified {
    // MARK: Stored
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var name: String
    @Attribute var category: ExerciseCategory
    @Attribute var instructions: String
    @Attribute var mediaAssetID: String?
    
    // MARK: Relationships
    @Relationship var completedSets: [CompletedSet]

    // MARK: Init
    init(
        id: UUID = UUID(),
        name: String,
        category: ExerciseCategory,
        instructions: String = "",
        mediaAssetID: String? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.instructions = instructions
        self.mediaAssetID = mediaAssetID
        self.completedSets = []
    }
}
