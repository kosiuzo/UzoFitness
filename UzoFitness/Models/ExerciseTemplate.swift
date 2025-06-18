import Foundation
import SwiftData

@Model
final class ExerciseTemplate: Identified {
    @Attribute(.unique) var id: UUID
    @Relationship var exercise: Exercise
    
    @Attribute var setCount: Int
    @Attribute var reps: Int
    @Attribute var weight: Double?
    @Attribute var position: Double
    @Attribute var supersetID: UUID?
    
    @Relationship var dayTemplate: DayTemplate?

    init(
        id: UUID = UUID(),
        exercise: Exercise,
        setCount: Int,
        reps: Int,
        weight: Double? = nil,
        position: Double,
        supersetID: UUID? = nil,
        dayTemplate: DayTemplate? = nil
    ) {
        self.id = id
        self.exercise = exercise
        self.setCount = setCount
        self.reps = reps
        self.weight = weight
        self.position = position
        self.supersetID = supersetID
        self.dayTemplate = dayTemplate
    }
}


// MARK: - ExerciseTemplate + Validation
extension ExerciseTemplate {
    /// Validates reps value
    private func validateReps() throws {
        guard reps >= 1 else {
            if reps == 0 {
                throw ValidationError.zeroReps
            } else {
                throw ValidationError.negativeReps(reps)
            }
        }
    }
    
    /// Validates set count value
    private func validateSetCount() throws {
        guard setCount >= 1 else {
            if setCount == 0 {
                throw ValidationError.zeroSets
            } else {
                throw ValidationError.negativeSetCount(setCount)
            }
        }
    }
    
    /// Validates weight value (if provided)
    private func validateWeight() throws {
        if let weight = weight {
            guard weight >= 0 else {
                throw ValidationError.negativeWeight(weight)
            }
        }
    }
    
    /// Validates position value
    private func validatePosition() throws {
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

// MARK: - ExerciseTemplate + Helper Methods
extension ExerciseTemplate {
    /// Validates specific reps value without creating an instance
    static func isValidReps(_ reps: Int) -> Bool {
        return reps >= 1
    }
    
    /// Validates specific set count value without creating an instance
    static func isValidSetCount(_ setCount: Int) -> Bool {
        return setCount >= 1
    }
    
    /// Validates specific weight value without creating an instance
    static func isValidWeight(_ weight: Double?) -> Bool {
        guard let weight = weight else { return true } // nil is valid
        return weight >= 0
    }
    
    /// Validates specific position value without creating an instance
    static func isValidPosition(_ position: Double) -> Bool {
        return position > 0
    }
    
    /// Validates all parameters without creating an instance
    static func areParametersValid(
        setCount: Int,
        reps: Int,
        weight: Double? = nil,
        position: Double
    ) -> (isValid: Bool, errors: [String]) {
        var errors: [String] = []
        
        if !isValidReps(reps) {
            if reps == 0 {
                errors.append("Reps must be at least 1")
            } else {
                errors.append("Reps cannot be negative: \(reps)")
            }
        }
        
        if !isValidSetCount(setCount) {
            if setCount == 0 {
                errors.append("Set count must be at least 1")
            } else {
                errors.append("Set count cannot be negative: \(setCount)")
            }
        }
        
        if !isValidWeight(weight) {
            errors.append("Weight cannot be negative: \(weight!)")
        }
        
        if !isValidPosition(position) {
            errors.append("Position must be positive: \(position)")
        }
        
        return (errors.isEmpty, errors)
    }
    
    /// Safely updates reps with validation
    func updateReps(_ newReps: Int) throws {
        let oldReps = self.reps
        self.reps = newReps
        
        do {
            try validateReps()
        } catch {
            // Revert on validation failure
            self.reps = oldReps
            throw error
        }
    }
    
    /// Safely updates set count with validation
    func updateSetCount(_ newSetCount: Int) throws {
        let oldSetCount = self.setCount
        self.setCount = newSetCount
        
        do {
            try validateSetCount()
        } catch {
            // Revert on validation failure
            self.setCount = oldSetCount
            throw error
        }
    }
    
    /// Safely updates weight with validation
    func updateWeight(_ newWeight: Double?) throws {
        let oldWeight = self.weight
        self.weight = newWeight
        
        do {
            try validateWeight()
        } catch {
            // Revert on validation failure
            self.weight = oldWeight
            throw error
        }
    }
    
    /// Safely updates position with validation
    func updatePosition(_ newPosition: Double) throws {
        let oldPosition = self.position
        self.position = newPosition
        
        do {
            try validatePosition()
        } catch {
            // Revert on validation failure
            self.position = oldPosition
            throw error
        }
    }
}
