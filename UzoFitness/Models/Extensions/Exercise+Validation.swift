//
//  Exercise+Validation.swift
//  UzoFitness
//
//  Created by Kosi Uzodinma on 6/17/25.
//

import Foundation
import SwiftData

extension ExerciseTemplate {
    /// Validates reps value
     func validateReps() throws {
        guard reps >= 1 else {
            if reps == 0 {
                throw ValidationError.zeroReps
            } else {
                throw ValidationError.negativeReps(reps)
            }
        }
    }
    
    /// Validates set count value
     func validateSetCount() throws {
        guard setCount >= 1 else {
            if setCount == 0 {
                throw ValidationError.zeroSets
            } else {
                throw ValidationError.negativeSetCount(setCount)
            }
        }
    }
    
    /// Validates weight value (if provided)
     func validateWeight() throws {
        if let weight = weight {
            guard weight >= 0 else {
                throw ValidationError.negativeWeight(weight)
            }
        }
    }
    
    /// Validates position value
     func validatePosition() throws {
        guard position > 0 else {
            throw ValidationError.invalidPosition(position)
        }
    }
    
    /// Validates all business rules for this exercise template
    func validate() throws {
        try validateReps()
        try validateSetCount()
        try validateWeight()
        try validatePosition()
    }
    
    /// Convenience method to validate and save
    func validateAndSave(in context: ModelContext) throws {
        try validate()
        try context.save()
    }
    
    /// Convenience method to validate before insert and save
    static func createAndSave(
        exercise: Exercise,
        setCount: Int,
        reps: Int,
        weight: Double? = nil,
        position: Double,
        supersetID: UUID? = nil,
        dayTemplate: DayTemplate? = nil,
        in context: ModelContext
    ) throws -> ExerciseTemplate {
        let template = ExerciseTemplate(
            exercise: exercise,
            setCount: setCount,
            reps: reps,
            weight: weight,
            position: position,
            supersetID: supersetID,
            dayTemplate: dayTemplate
        )
        
        context.insert(template)
        try template.validateAndSave(in: context)
        return template
    }
}
