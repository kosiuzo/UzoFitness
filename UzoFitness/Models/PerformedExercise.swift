//
//  PerformedExercise.swift
//  UzoFitness
//
//  Created by Kosi Uzodinma on 6/17/25.
//


import Foundation
import SwiftData

@Model
final class PerformedExercise: Identified {
    @Attribute(.unique) var id: UUID
    @Attribute var performedAt: Date
    @Attribute var reps: Int
    @Attribute var weight: Double

    @Relationship var exercise: Exercise
    @Relationship var workoutSession: WorkoutSession?

    init(
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
}