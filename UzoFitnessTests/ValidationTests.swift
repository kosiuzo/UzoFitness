//
//  ValidationTests.swift
//  UzoFitnessTests
//
//  Checks uniqueness constraints & simple invariants.
//

import XCTest
import SwiftData
@testable import UzoFitness

@MainActor
final class ValidationTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    
    override func setUp() async throws {
        // Create a proper in-memory container with your model schema
        let schema = Schema([
            WorkoutTemplate.self,
            ExerciseTemplate.self,
            // Add any other models that WorkoutTemplate might reference
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        container = try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
        
        context = ModelContext(container)
    }
    
    override func tearDown() async throws {
        container = nil
        context = nil
    }
    
    func testUniqueWorkoutTemplateName() async throws {
        let name = "PPL"
        
        // Insert first template successfully
        let firstTemplate = WorkoutTemplate(name: name)
        context.insert(firstTemplate)
        try context.save()
        
        // Try to create duplicate - this should fail
        let duplicateTemplate = WorkoutTemplate(name: name)
        context.insert(duplicateTemplate)
        
        // This should throw either our ValidationError or SwiftData's constraint error
        XCTAssertThrowsError(try duplicateTemplate.validateAndSave(in: context)) { error in
            // Could be our custom validation error
            if let validationError = error as? ValidationError {
                print("Custom validation error: \(validationError.localizedDescription)")
                XCTAssertTrue(true, "Expected custom validation error")
            }
            // Or could be SwiftData's constraint violation
            else {
                print("SwiftData constraint error: \(error)")
                // SwiftData constraint errors are typically NSError with specific codes
                XCTAssertTrue(true, "Expected SwiftData constraint error")
            }
        }
    }
    
    func testWorkoutTemplateNameValidation() throws {
        // Test empty name
        XCTAssertThrowsError(try WorkoutTemplate.createAndSave(name: "", in: context)) { error in
            XCTAssertTrue(error is ValidationError)
        }
        
        // Test whitespace-only name
        XCTAssertThrowsError(try WorkoutTemplate.createAndSave(name: "   ", in: context)) { error in
            XCTAssertTrue(error is ValidationError)
        }
        
        // Test name that's too long
        let longName = String(repeating: "a", count: 101)
        XCTAssertThrowsError(try WorkoutTemplate.createAndSave(name: longName, in: context)) { error in
            XCTAssertTrue(error is ValidationError)
        }
        
        // Test valid name (should succeed)
        XCTAssertNoThrow(try WorkoutTemplate.createAndSave(name: "Valid Workout", in: context))
    }

    func testWorkoutTemplateNameSuggestion() throws {
        // Create a template
        _ = try WorkoutTemplate.createAndSave(name: "PPL", in: context)
        
        // Check that the name is no longer available
        XCTAssertFalse(try WorkoutTemplate.isNameAvailable("PPL", in: context))
        
        // Get a suggested alternative name
        let suggestion = try WorkoutTemplate.suggestAvailableName("PPL", in: context)
        XCTAssertEqual(suggestion, "PPL 2")
        
        // Verify the suggestion is actually available
        XCTAssertTrue(try WorkoutTemplate.isNameAvailable(suggestion, in: context))
    }

    func testExerciseTemplateNegativeRepsFails() throws {
        let ex = Exercise(name: "Curl", category: .strength)
        context.insert(ex)
        
        // Test negative reps
        XCTAssertThrowsError(try ExerciseTemplate.createAndSave(
            exercise: ex,
            setCount: 3,
            reps: -5,
            position: 1.0,
            in: context
        )) { error in
            XCTAssertTrue(error is ValidationError)
            print("Expected negative reps error: \(error)")
        }
    }

    func testExerciseTemplateZeroRepsFails() throws {
        let ex = Exercise(name: "Curl", category: .strength)
        context.insert(ex)
        
        // Test zero reps
        XCTAssertThrowsError(try ExerciseTemplate.createAndSave(
            exercise: ex,
            setCount: 3,
            reps: 0,
            position: 1.0,
            in: context
        )) { error in
            XCTAssertTrue(error is ValidationError)
            print("Expected zero reps error: \(error)")
        }
    }

    func testExerciseTemplateNegativeSetCountFails() throws {
        let ex = Exercise(name: "Curl", category: .strength)
        context.insert(ex)
        
        // Test negative set count
        XCTAssertThrowsError(try ExerciseTemplate.createAndSave(
            exercise: ex,
            setCount: -1,
            reps: 5,
            position: 1.0,
            in: context
        )) { error in
            XCTAssertTrue(error is ValidationError)
            print("Expected negative set count error: \(error)")
        }
    }

    func testExerciseTemplateNegativeWeightFails() throws {
        let ex = Exercise(name: "Curl", category: .strength)
        context.insert(ex)
        
        // Test negative weight
        XCTAssertThrowsError(try ExerciseTemplate.createAndSave(
            exercise: ex,
            setCount: 3,
            reps: 5,
            weight: -10.0,
            position: 1.0,
            in: context
        )) { error in
            XCTAssertTrue(error is ValidationError)
            print("Expected negative weight error: \(error)")
        }
    }

    func testExerciseTemplateInvalidPositionFails() throws {
        let ex = Exercise(name: "Curl", category: .strength)
        context.insert(ex)
        
        // Test zero/negative position
        XCTAssertThrowsError(try ExerciseTemplate.createAndSave(
            exercise: ex,
            setCount: 3,
            reps: 5,
            position: 0.0,
            in: context
        )) { error in
            XCTAssertTrue(error is ValidationError)
            print("Expected invalid position error: \(error)")
        }
    }

    func testValidExerciseTemplateSucceeds() throws {
        let ex = Exercise(name: "Squat", category: .strength)
        context.insert(ex)
        
        // This should succeed
        XCTAssertNoThrow(try ExerciseTemplate.createAndSave(
            exercise: ex,
            setCount: 3,
            reps: 10,
            weight: 135.0,
            position: 1.0,
            in: context
        ))
    }

    func testExerciseTemplateParameterValidation() throws {
        // Test static validation helpers
        XCTAssertTrue(ExerciseTemplate.isValidReps(10))
        XCTAssertFalse(ExerciseTemplate.isValidReps(-5))
        XCTAssertFalse(ExerciseTemplate.isValidReps(0))
        
        XCTAssertTrue(ExerciseTemplate.isValidSetCount(3))
        XCTAssertFalse(ExerciseTemplate.isValidSetCount(-1))
        XCTAssertFalse(ExerciseTemplate.isValidSetCount(0))
        
        XCTAssertTrue(ExerciseTemplate.isValidWeight(nil))
        XCTAssertTrue(ExerciseTemplate.isValidWeight(135.0))
        XCTAssertFalse(ExerciseTemplate.isValidWeight(-10.0))
        
        XCTAssertTrue(ExerciseTemplate.isValidPosition(1.0))
        XCTAssertFalse(ExerciseTemplate.isValidPosition(0.0))
        XCTAssertFalse(ExerciseTemplate.isValidPosition(-1.0))
    }

    func testExerciseTemplateBatchValidation() throws {
        let validation = ExerciseTemplate.areParametersValid(
            setCount: 3,
            reps: 10,
            weight: 135.0,
            position: 1.0
        )
        XCTAssertTrue(validation.isValid)
        XCTAssertTrue(validation.errors.isEmpty)
        
        let invalidValidation = ExerciseTemplate.areParametersValid(
            setCount: -1,
            reps: 0,
            weight: -10.0,
            position: 0.0
        )
        XCTAssertFalse(invalidValidation.isValid)
        XCTAssertEqual(invalidValidation.errors.count, 4)
    }

    func testExerciseTemplateSafeUpdates() throws {
        let ex = Exercise(name: "Bench Press", category: .strength)
        context.insert(ex)
        
        let template = try ExerciseTemplate.createAndSave(
            exercise: ex,
            setCount: 3,
            reps: 10,
            position: 1.0,
            in: context
        )
        
        // Test safe updates
        XCTAssertNoThrow(try template.updateReps(12))
        XCTAssertEqual(template.reps, 12)
        
        XCTAssertThrowsError(try template.updateReps(-5)) { error in
            XCTAssertTrue(error is ValidationError)
            // Value should be reverted
            XCTAssertEqual(template.reps, 12)
        }
        
        XCTAssertNoThrow(try template.updateWeight(225.0))
        XCTAssertEqual(template.weight, 225.0)
        
        XCTAssertThrowsError(try template.updateWeight(-50.0)) { error in
            XCTAssertTrue(error is ValidationError)
            // Value should be reverted
            XCTAssertEqual(template.weight, 225.0)
        }
    }
}
