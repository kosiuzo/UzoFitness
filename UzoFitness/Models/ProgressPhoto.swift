import Foundation
import SwiftData

@Model
final class ProgressPhoto: Identified, Timestamped {
    @Attribute(.unique) var id: UUID
    @Attribute var date: Date
    @Attribute var angle: PhotoAngle
    @Attribute var assetIdentifier: String
    @Attribute var weightSampleUUID: UUID?
    @Attribute var notes: String
    @Attribute var createdAt: Date

    init(
        id: UUID = UUID(),
        date: Date,
        angle: PhotoAngle,
        assetIdentifier: String,
        weightSampleUUID: UUID? = nil,
        notes: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.date = date
        self.angle = angle
        self.assetIdentifier = assetIdentifier
        self.weightSampleUUID = weightSampleUUID
        self.notes = notes
        self.createdAt = createdAt
    }
}
