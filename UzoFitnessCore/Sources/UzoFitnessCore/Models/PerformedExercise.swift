//
//  PerformedExercise.swift
//  UzoFitness
//
//  Created by Kosi Uzodinma on 6/17/25.
//


import Foundation
import SwiftData

@Model
public final class PerformedExercise: Identified, Codable {
    @Attribute(.unique) public var id: UUID
    @Attribute public var performedAt: Date
    @Attribute public var reps: Int
    @Attribute public var weight: Double

    @Relationship public var exercise: Exercise
    @Relationship public var workoutSession: WorkoutSession?

    public init(
        id: UUID = UUID(),
        performedAt: Date = .now,
        reps: Int,
        weight: Double,
        exercise: Exercise,
        workoutSession: WorkoutSession? = nil
    ) {
        self.id = id
        self.performedAt = performedAt
        self.reps = reps
        self.weight = weight
        self.exercise = exercise
        self.workoutSession = workoutSession
    }

    // MARK: - Codable Implementation
    enum CodingKeys: CodingKey {
        case id, performedAt, reps, weight
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(performedAt, forKey: .performedAt)
        try container.encode(reps, forKey: .reps)
        try container.encode(weight, forKey: .weight)
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.performedAt = try container.decode(Date.self, forKey: .performedAt)
        self.reps = try container.decode(Int.self, forKey: .reps)
        self.weight = try container.decode(Double.self, forKey: .weight)
        self.exercise = Exercise(id: UUID(), name: "", category: .strength) // Placeholder, should be set after decoding
        self.workoutSession = nil
    }
}