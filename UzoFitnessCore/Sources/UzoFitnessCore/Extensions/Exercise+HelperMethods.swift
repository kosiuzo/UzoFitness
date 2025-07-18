//
//  Exercise+HelperMethods.swift
//  UzoFitness
//
//  Created by Kosi Uzodinma on 6/17/25.
//


// MARK: - ExerciseTemplate + Helper Methods
extension ExerciseTemplate {
    /// Validates specific reps value without creating an instance
    public static func isValidReps(_ reps: Int) -> Bool {
        return reps >= 1
    }
    
    /// Validates specific set count value without creating an instance
    public static func isValidSetCount(_ setCount: Int) -> Bool {
        return setCount >= 1
    }
    
    /// Validates specific weight value without creating an instance
    public static func isValidWeight(_ weight: Double?) -> Bool {
        guard let weight = weight else { return true } // nil is valid
        return weight >= 0
    }
    
    /// Validates specific position value without creating an instance
    public static func isValidPosition(_ position: Double) -> Bool {
        return position > 0
    }
    
    /// Validates all parameters without creating an instance
    public static func areParametersValid(
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
    public func updateReps(_ newReps: Int) throws {
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
    public func updateSetCount(_ newSetCount: Int) throws {
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
    public func updateWeight(_ newWeight: Double?) throws {
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
    public func updatePosition(_ newPosition: Double) throws {
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