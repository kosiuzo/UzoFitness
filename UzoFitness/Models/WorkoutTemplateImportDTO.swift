import Foundation
import SwiftData

// MARK: - Data Transfer Objects for JSON Import

/// Data Transfer Object for importing workout templates from JSON
struct WorkoutTemplateImportDTO: Codable {
    let name: String
    let summary: String
    let createdAt: Date?
    let days: [DayImportDTO]
    
    enum CodingKeys: String, CodingKey {
        case name, summary, createdAt, days
    }
    
    /// Validates the imported data for consistency and completeness
    func validate() throws {
        print("🔄 [WorkoutTemplateImportDTO.validate] Starting validation")
        
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ImportError.emptyTemplateName
        }
        
        guard name.count <= 100 else {
            throw ImportError.templateNameTooLong(name.count)
        }
        
        guard !days.isEmpty else {
            throw ImportError.noDaysProvided
        }
        
        // Validate each day
        for (index, day) in days.enumerated() {
            do {
                try day.validate()
            } catch {
                throw ImportError.dayValidationFailed(dayIndex: index, underlyingError: error)
            }
        }
        
        print("✅ [WorkoutTemplateImportDTO.validate] Validation successful")
    }
}

/// Data Transfer Object for importing day templates from JSON
struct DayImportDTO: Codable {
    let dayIndex: Int
    let name: String
    let exercises: [ExerciseImportDTO]
    
    enum CodingKeys: String, CodingKey {
        case dayIndex, name, exercises
    }
    
    /// Validates the imported day data
    func validate() throws {
        print("🔄 [DayImportDTO.validate] Starting validation for day: \(name)")
        
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ImportError.emptyDayName
        }
        
        guard dayIndex >= 1 && dayIndex <= 7 else {
            throw ImportError.invalidDayIndex(dayIndex)
        }
        
        guard !exercises.isEmpty else {
            throw ImportError.noExercisesProvided
        }
        
        // Validate each exercise
        for (index, exercise) in exercises.enumerated() {
            do {
                try exercise.validate()
            } catch {
                throw ImportError.exerciseValidationFailed(exerciseIndex: index, underlyingError: error)
            }
        }
        
        print("✅ [DayImportDTO.validate] Validation successful for day: \(name)")
    }
}

/// Data Transfer Object for importing exercise templates from JSON
struct ExerciseImportDTO: Codable {
    let name: String
    let sets: Int
    let reps: Int
    let weight: Double?
    let supersetGroup: Int?
    
    enum CodingKeys: String, CodingKey {
        case name, sets, reps, weight, supersetGroup
    }
    
    /// Validates the imported exercise data
    func validate() throws {
        print("🔄 [ExerciseImportDTO.validate] Starting validation for exercise: \(name)")
        
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ImportError.emptyExerciseName
        }
        
        guard sets > 0 else {
            throw ImportError.invalidSets(sets)
        }
        
        guard reps > 0 else {
            throw ImportError.invalidReps(reps)
        }
        
        if let weight = weight, weight < 0 {
            throw ImportError.invalidWeight(weight)
        }
        
        if let supersetGroup = supersetGroup, supersetGroup <= 0 {
            throw ImportError.invalidSupersetGroup(supersetGroup)
        }
        
        print("✅ [ExerciseImportDTO.validate] Validation successful for exercise: \(name)")
    }
}

// MARK: - Import Errors

enum ImportError: Error, LocalizedError {
    case emptyTemplateName
    case templateNameTooLong(Int)
    case noDaysProvided
    case emptyDayName
    case invalidDayIndex(Int)
    case noExercisesProvided
    case emptyExerciseName
    case invalidSets(Int)
    case invalidReps(Int)
    case invalidWeight(Double)
    case invalidSupersetGroup(Int)
    case dayValidationFailed(dayIndex: Int, underlyingError: Error)
    case exerciseValidationFailed(exerciseIndex: Int, underlyingError: Error)
    case jsonDecodingFailed(Error)
    case duplicateTemplate(String)
    
    var errorDescription: String? {
        switch self {
        case .emptyTemplateName:
            return "Template name cannot be empty"
        case .templateNameTooLong(let count):
            return "Template name is too long (\(count) characters). Maximum is 100 characters"
        case .noDaysProvided:
            return "Template must have at least one day"
        case .emptyDayName:
            return "Day name cannot be empty"
        case .invalidDayIndex(let index):
            return "Day index must be between 1 and 7, got \(index)"
        case .noExercisesProvided:
            return "Day must have at least one exercise"
        case .emptyExerciseName:
            return "Exercise name cannot be empty"
        case .invalidSets(let sets):
            return "Sets must be greater than 0, got \(sets)"
        case .invalidReps(let reps):
            return "Reps must be greater than 0, got \(reps)"
        case .invalidWeight(let weight):
            return "Weight cannot be negative, got \(weight)"
        case .invalidSupersetGroup(let group):
            return "Superset group must be greater than 0, got \(group)"
        case .dayValidationFailed(let dayIndex, let underlyingError):
            return "Day \(dayIndex + 1) validation failed: \(underlyingError.localizedDescription)"
        case .exerciseValidationFailed(let exerciseIndex, let underlyingError):
            return "Exercise \(exerciseIndex + 1) validation failed: \(underlyingError.localizedDescription)"
        case .jsonDecodingFailed(let error):
            return "JSON decoding failed: \(error.localizedDescription)"
        case .duplicateTemplate(let name):
            return "A template with name '\(name)' already exists"
        }
    }
} 