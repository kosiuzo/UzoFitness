import Foundation
import SwiftData
import Testing
import UzoFitnessCore
@testable import UzoFitness

/// Tests to verify validation logic for WorkoutTemplate and ExerciseTemplate
@MainActor
final class ValidationTests {
    
    // MARK: - Test Properties
    private var persistenceController: InMemoryPersistenceController!
    
    // MARK: - Setup and Teardown
    
    private func setUp() {
        persistenceController = InMemoryPersistenceController()
        persistenceController.cleanupTestData()
    }
    
    private func tearDown() {
        persistenceController?.cleanupTestData()
        persistenceController = nil
    }
    
    // MARK: - WorkoutTemplate Validation Tests
    
    @Test("WorkoutTemplate unique name validation succeeds for different names")
    func testUniqueWorkoutTemplateName() async throws {
        print("🔄 [ValidationTests.testUniqueWorkoutTemplateName] Starting test")
        
        setUp()
        defer { tearDown() }
        
        // Create first template
        let template1 = WorkoutTemplate(name: "Upper Body", summary: "First template")
        persistenceController.create(template1)
        
        // Create second template with different name - should succeed
        let template2 = WorkoutTemplate(name: "Lower Body", summary: "Second template")
        persistenceController.create(template2)
        
        // Validate both templates
        #expect(throws: Never.self) {
            try template1.validate(in: persistenceController.context)
        }
        
        #expect(throws: Never.self) {
            try template2.validate(in: persistenceController.context)
        }
        
        print("✅ [ValidationTests.testUniqueWorkoutTemplateName] Test completed")
    }
    
    @Test("WorkoutTemplate duplicate name validation fails correctly")
    func testDuplicateWorkoutTemplateNameValidation() async throws {
        print("🔄 [ValidationTests.testDuplicateWorkoutTemplateNameValidation] Starting test")
        
        setUp()
        defer { tearDown() }
        
        // Create first template
        let template1 = WorkoutTemplate(name: "Upper Body", summary: "First template")
        persistenceController.create(template1)
        
        // Validate first template - should succeed
        #expect(throws: Never.self) {
            try template1.validate(in: persistenceController.context)
        }
        
        // Create second template with same name
        let template2 = WorkoutTemplate(name: "Upper Body", summary: "Second template")
        persistenceController.create(template2)
        
        // Validate second template - should fail with duplicate name error
        #expect(throws: ValidationError.self) {
            try template2.validate(in: persistenceController.context)
        }
        
        print("✅ [ValidationTests.testDuplicateWorkoutTemplateNameValidation] Test completed")
    }
    
    @Test("WorkoutTemplate name validation handles edge cases correctly")
    func testWorkoutTemplateNameValidation() async throws {
        print("🔄 [ValidationTests.testWorkoutTemplateNameValidation] Starting test")
        
        setUp()
        defer { tearDown() }
        
        // Test empty name
        let emptyTemplate = WorkoutTemplate(name: "", summary: "Empty name")
        persistenceController.create(emptyTemplate)
        
        #expect(throws: ValidationError.self) {
            try emptyTemplate.validate(in: persistenceController.context)
        }
        
        // Test whitespace only name
        let whitespaceTemplate = WorkoutTemplate(name: "   ", summary: "Whitespace name")
        persistenceController.create(whitespaceTemplate)
        
        #expect(throws: ValidationError.self) {
            try whitespaceTemplate.validate(in: persistenceController.context)
        }
        
        // Test name that's too long (over 100 characters)
        let longName = String(repeating: "a", count: 101)
        let longTemplate = WorkoutTemplate(name: longName, summary: "Long name")
        persistenceController.create(longTemplate)
        
        #expect(throws: ValidationError.self) {
            try longTemplate.validate(in: persistenceController.context)
        }
        
        // Test valid name with whitespace trimming
        let validTemplate = WorkoutTemplate(name: "  Valid Name  ", summary: "Valid template")
        persistenceController.create(validTemplate)
        
        #expect(throws: Never.self) {
            try validTemplate.validate(in: persistenceController.context)
        }
        
        // Verify name was trimmed
        #expect(validTemplate.name == "Valid Name")
        
        print("✅ [ValidationTests.testWorkoutTemplateNameValidation] Test completed")
    }
    
    @Test("WorkoutTemplate name suggestion works correctly")
    func testWorkoutTemplateNameSuggestion() async throws {
        print("🔄 [ValidationTests.testWorkoutTemplateNameSuggestion] Starting test")
        
        setUp()
        defer { tearDown() }
        
        // Test case insensitive duplicate detection
        let template1 = WorkoutTemplate(name: "Upper Body", summary: "First template")
        persistenceController.create(template1)
        
        #expect(throws: Never.self) {
            try template1.validate(in: persistenceController.context)
        }
        
        // Test different case variations should fail
        let template2 = WorkoutTemplate(name: "UPPER BODY", summary: "Second template")
        persistenceController.create(template2)
        
        #expect(throws: ValidationError.self) {
            try template2.validate(in: persistenceController.context)
        }
        
        let template3 = WorkoutTemplate(name: "upper body", summary: "Third template")
        persistenceController.create(template3)
        
        #expect(throws: ValidationError.self) {
            try template3.validate(in: persistenceController.context)
        }
        
        print("✅ [ValidationTests.testWorkoutTemplateNameSuggestion] Test completed")
    }
    
    @Test("ValidationError enum cases have correct error descriptions")
    func testValidationErrorDescriptions() async throws {
        print("🔄 [ValidationTests.testValidationErrorDescriptions] Starting test")
        
        // Test duplicate name error
        let duplicateError = ValidationError.duplicateWorkoutTemplateName("Test Name")
        #expect(duplicateError.errorDescription == "A workout template with name 'Test Name' already exists")
        
        // Test empty name error
        let emptyError = ValidationError.emptyWorkoutTemplateName
        #expect(emptyError.errorDescription == "Workout template name cannot be empty")
        
        // Test long name error
        let longError = ValidationError.workoutTemplateNameTooLong(150)
        #expect(longError.errorDescription == "Workout template name is too long (150 characters). Maximum is 100 characters.")
        
        // Test negative reps error
        let negativeRepsError = ValidationError.negativeReps(-5)
        #expect(negativeRepsError.errorDescription == "Reps cannot be negative: -5")
        
        // Test zero reps error
        let zeroRepsError = ValidationError.zeroReps
        #expect(zeroRepsError.errorDescription == "Reps must be at least 1")
        
        // Test negative sets error
        let negativeSetsError = ValidationError.negativeSetCount(-3)
        #expect(negativeSetsError.errorDescription == "Set count cannot be negative: -3")
        
        // Test zero sets error
        let zeroSetsError = ValidationError.zeroSets
        #expect(zeroSetsError.errorDescription == "Set count must be at least 1")
        
        // Test negative weight error
        let negativeWeightError = ValidationError.negativeWeight(-50.0)
        #expect(negativeWeightError.errorDescription == "Weight cannot be negative: -50.0")
        
        // Test invalid position error
        let invalidPositionError = ValidationError.invalidPosition(-1.0)
        #expect(invalidPositionError.errorDescription == "Position must be positive: -1.0")
        
        // Test custom error
        let customError = ValidationError.custom("Custom error message")
        #expect(customError.errorDescription == "Custom error message")
        
        print("✅ [ValidationTests.testValidationErrorDescriptions] Test completed")
    }
    
    // MARK: - ExerciseTemplate Validation Tests
    
    @Test("ExerciseTemplate parameter validation succeeds for valid values")
    func testValidExerciseTemplateParameters() async throws {
        print("🔄 [ValidationTests.testValidExerciseTemplateParameters] Starting test")
        
        setUp()
        defer { tearDown() }
        
        let exercise = TestHelpers.createTestExercise(name: "Test Exercise")
        persistenceController.create(exercise)
        
        let template = ExerciseTemplate(
            exercise: exercise,
            setCount: 3,
            reps: 10,
            weight: 100.0,
            position: 1.0
        )
        persistenceController.create(template)
        
        // Validate all parameters - should succeed
        #expect(throws: Never.self) {
            try template.validate()
        }
        
        print("✅ [ValidationTests.testValidExerciseTemplateParameters] Test completed")
    }
    
    @Test("ExerciseTemplate validates reps correctly")
    func testExerciseTemplateRepsValidation() async throws {
        print("🔄 [ValidationTests.testExerciseTemplateRepsValidation] Starting test")
        
        setUp()
        defer { tearDown() }
        
        let exercise = TestHelpers.createTestExercise(name: "Test Exercise")
        persistenceController.create(exercise)
        
        // Test negative reps
        let negativeRepsTemplate = ExerciseTemplate(
            exercise: exercise,
            setCount: 3,
            reps: -5,
            position: 1.0
        )
        
        #expect(throws: ValidationError.self) {
            try negativeRepsTemplate.validate()
        }
        
        // Test zero reps
        let zeroRepsTemplate = ExerciseTemplate(
            exercise: exercise,
            setCount: 3,
            reps: 0,
            position: 1.0
        )
        
        #expect(throws: ValidationError.self) {
            try zeroRepsTemplate.validate()
        }
        
        // Test valid reps
        let validRepsTemplate = ExerciseTemplate(
            exercise: exercise,
            setCount: 3,
            reps: 10,
            position: 1.0
        )
        
        #expect(throws: Never.self) {
            try validRepsTemplate.validate()
        }
        
        print("✅ [ValidationTests.testExerciseTemplateRepsValidation] Test completed")
    }
    
    @Test("ExerciseTemplate validates set count correctly")
    func testExerciseTemplateSetCountValidation() async throws {
        print("🔄 [ValidationTests.testExerciseTemplateSetCountValidation] Starting test")
        
        setUp()
        defer { tearDown() }
        
        let exercise = TestHelpers.createTestExercise(name: "Test Exercise")
        persistenceController.create(exercise)
        
        // Test negative set count
        let negativeSetsTemplate = ExerciseTemplate(
            exercise: exercise,
            setCount: -2,
            reps: 10,
            position: 1.0
        )
        
        #expect(throws: ValidationError.self) {
            try negativeSetsTemplate.validate()
        }
        
        // Test zero set count
        let zeroSetsTemplate = ExerciseTemplate(
            exercise: exercise,
            setCount: 0,
            reps: 10,
            position: 1.0
        )
        
        #expect(throws: ValidationError.self) {
            try zeroSetsTemplate.validate()
        }
        
        // Test valid set count
        let validSetsTemplate = ExerciseTemplate(
            exercise: exercise,
            setCount: 3,
            reps: 10,
            position: 1.0
        )
        
        #expect(throws: Never.self) {
            try validSetsTemplate.validate()
        }
        
        print("✅ [ValidationTests.testExerciseTemplateSetCountValidation] Test completed")
    }
    
    @Test("ExerciseTemplate validates weight correctly")
    func testExerciseTemplateWeightValidation() async throws {
        print("🔄 [ValidationTests.testExerciseTemplateWeightValidation] Starting test")
        
        setUp()
        defer { tearDown() }
        
        let exercise = TestHelpers.createTestExercise(name: "Test Exercise")
        persistenceController.create(exercise)
        
        // Test negative weight
        let negativeWeightTemplate = ExerciseTemplate(
            exercise: exercise,
            setCount: 3,
            reps: 10,
            weight: -50.0,
            position: 1.0
        )
        
        #expect(throws: ValidationError.self) {
            try negativeWeightTemplate.validate()
        }
        
        // Test zero weight (should be valid)
        let zeroWeightTemplate = ExerciseTemplate(
            exercise: exercise,
            setCount: 3,
            reps: 10,
            weight: 0.0,
            position: 1.0
        )
        
        #expect(throws: Never.self) {
            try zeroWeightTemplate.validate()
        }
        
        // Test positive weight
        let positiveWeightTemplate = ExerciseTemplate(
            exercise: exercise,
            setCount: 3,
            reps: 10,
            weight: 100.0,
            position: 1.0
        )
        
        #expect(throws: Never.self) {
            try positiveWeightTemplate.validate()
        }
        
        // Test nil weight (bodyweight exercise)
        let bodyweightTemplate = ExerciseTemplate(
            exercise: exercise,
            setCount: 3,
            reps: 10,
            weight: nil,
            position: 1.0
        )
        
        #expect(throws: Never.self) {
            try bodyweightTemplate.validate()
        }
        
        print("✅ [ValidationTests.testExerciseTemplateWeightValidation] Test completed")
    }
    
    @Test("ExerciseTemplate validates position correctly")
    func testExerciseTemplatePositionValidation() async throws {
        print("🔄 [ValidationTests.testExerciseTemplatePositionValidation] Starting test")
        
        setUp()
        defer { tearDown() }
        
        let exercise = TestHelpers.createTestExercise(name: "Test Exercise")
        persistenceController.create(exercise)
        
        // Test negative position
        let negativePositionTemplate = ExerciseTemplate(
            exercise: exercise,
            setCount: 3,
            reps: 10,
            position: -1.0
        )
        
        #expect(throws: ValidationError.self) {
            try negativePositionTemplate.validate()
        }
        
        // Test zero position
        let zeroPositionTemplate = ExerciseTemplate(
            exercise: exercise,
            setCount: 3,
            reps: 10,
            position: 0.0
        )
        
        #expect(throws: ValidationError.self) {
            try zeroPositionTemplate.validate()
        }
        
        // Test valid position
        let validPositionTemplate = ExerciseTemplate(
            exercise: exercise,
            setCount: 3,
            reps: 10,
            position: 1.0
        )
        
        #expect(throws: Never.self) {
            try validPositionTemplate.validate()
        }
        
        print("✅ [ValidationTests.testExerciseTemplatePositionValidation] Test completed")
    }
    
    @Test("ExerciseTemplate safe updates with rollback on validation failure")
    func testExerciseTemplateSafeUpdates() async throws {
        print("🔄 [ValidationTests.testExerciseTemplateSafeUpdates] Starting test")
        
        setUp()
        defer { tearDown() }
        
        let exercise = TestHelpers.createTestExercise(name: "Test Exercise")
        persistenceController.create(exercise)
        
        // Create valid template
        let template = ExerciseTemplate(
            exercise: exercise,
            setCount: 3,
            reps: 10,
            weight: 100.0,
            position: 1.0
        )
        persistenceController.create(template)
        
        // Verify initial valid state
        #expect(throws: Never.self) {
            try template.validate()
        }
        
        // Store original values
        let originalSetCount = template.setCount
        let originalReps = template.reps
        let originalWeight = template.weight
        let originalPosition = template.position
        
        // Make invalid changes
        template.setCount = -1
        template.reps = -5
        template.weight = -50.0
        template.position = -1.0
        
        // Validation should fail
        #expect(throws: ValidationError.self) {
            try template.validate()
        }
        
        // Rollback changes and verify original values are restored
        template.setCount = originalSetCount
        template.reps = originalReps
        template.weight = originalWeight
        template.position = originalPosition
        
        // Should validate successfully again
        #expect(throws: Never.self) {
            try template.validate()
        }
        
        print("✅ [ValidationTests.testExerciseTemplateSafeUpdates] Test completed")
    }
    
    // MARK: - Enum Tests
    
    @Test("Weekday enum raw value mapping matches Calendar weekday values")
    func testWeekdayRawValueMapping() async throws {
        print("🔄 [ValidationTests.testWeekdayRawValueMapping] Starting test")
        
        // Test that Weekday raw values match Calendar.current.component(.weekday, from: Date())
        // Calendar weekday values: Sunday = 1, Monday = 2, Tuesday = 3, etc.
        
        // Test specific raw value mappings
        #expect(Weekday(rawValue: 1) == .sunday)
        #expect(Weekday(rawValue: 2) == .monday)
        #expect(Weekday(rawValue: 3) == .tuesday)
        #expect(Weekday(rawValue: 4) == .wednesday)
        #expect(Weekday(rawValue: 5) == .thursday)
        #expect(Weekday(rawValue: 6) == .friday)
        #expect(Weekday(rawValue: 7) == .saturday)
        
        // Test that invalid raw values return nil
        #expect(Weekday(rawValue: 0) == nil)
        #expect(Weekday(rawValue: 8) == nil)
        #expect(Weekday(rawValue: -1) == nil)
        
        // Test that all cases have correct raw values
        #expect(Weekday.sunday.rawValue == 1)
        #expect(Weekday.monday.rawValue == 2)
        #expect(Weekday.tuesday.rawValue == 3)
        #expect(Weekday.wednesday.rawValue == 4)
        #expect(Weekday.thursday.rawValue == 5)
        #expect(Weekday.friday.rawValue == 6)
        #expect(Weekday.saturday.rawValue == 7)
        
        // Test case order matches CaseIterable order
        let expectedOrder: [Weekday] = [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]
        #expect(Array(Weekday.allCases) == expectedOrder)
        
        print("✅ [ValidationTests.testWeekdayRawValueMapping] Test completed")
    }
    
    @Test("Weekday enum string properties return correct values")
    func testWeekdayStringProperties() async throws {
        print("🔄 [ValidationTests.testWeekdayStringProperties] Starting test")
        
        // Test abbreviations
        #expect(Weekday.sunday.abbreviation == "SUN")
        #expect(Weekday.monday.abbreviation == "MON")
        #expect(Weekday.tuesday.abbreviation == "TUE")
        #expect(Weekday.wednesday.abbreviation == "WED")
        #expect(Weekday.thursday.abbreviation == "THU")
        #expect(Weekday.friday.abbreviation == "FRI")
        #expect(Weekday.saturday.abbreviation == "SAT")
        
        // Test full names
        #expect(Weekday.sunday.fullName == "Sunday")
        #expect(Weekday.monday.fullName == "Monday")
        #expect(Weekday.tuesday.fullName == "Tuesday")
        #expect(Weekday.wednesday.fullName == "Wednesday")
        #expect(Weekday.thursday.fullName == "Thursday")
        #expect(Weekday.friday.fullName == "Friday")
        #expect(Weekday.saturday.fullName == "Saturday")
        
        print("✅ [ValidationTests.testWeekdayStringProperties] Test completed")
    }
    
    @Test("Weekday.from(string:) method handles various string formats")
    func testWeekdayFromString() async throws {
        print("🔄 [ValidationTests.testWeekdayFromString] Starting test")
        
        // Test full names (case insensitive)
        #expect(Weekday.from(string: "monday") == .monday)
        #expect(Weekday.from(string: "MONDAY") == .monday)
        #expect(Weekday.from(string: "Monday") == .monday)
        
        // Test abbreviations
        #expect(Weekday.from(string: "mon") == .monday)
        #expect(Weekday.from(string: "MON") == .monday)
        #expect(Weekday.from(string: "Mon") == .monday)
        
        // Test all days
        #expect(Weekday.from(string: "sunday") == .sunday)
        #expect(Weekday.from(string: "sun") == .sunday)
        #expect(Weekday.from(string: "tuesday") == .tuesday)
        #expect(Weekday.from(string: "tue") == .tuesday)
        #expect(Weekday.from(string: "tues") == .tuesday)
        #expect(Weekday.from(string: "wednesday") == .wednesday)
        #expect(Weekday.from(string: "wed") == .wednesday)
        #expect(Weekday.from(string: "thursday") == .thursday)
        #expect(Weekday.from(string: "thu") == .thursday)
        #expect(Weekday.from(string: "thur") == .thursday)
        #expect(Weekday.from(string: "thurs") == .thursday)
        #expect(Weekday.from(string: "friday") == .friday)
        #expect(Weekday.from(string: "fri") == .friday)
        #expect(Weekday.from(string: "saturday") == .saturday)
        #expect(Weekday.from(string: "sat") == .saturday)
        
        // Test whitespace handling
        #expect(Weekday.from(string: "  monday  ") == .monday)
        #expect(Weekday.from(string: "\ttuesday\n") == .tuesday)
        
        // Test invalid strings
        #expect(Weekday.from(string: "invalid") == nil)
        #expect(Weekday.from(string: "") == nil)
        #expect(Weekday.from(string: "   ") == nil)
        #expect(Weekday.from(string: "weekday") == nil)
        
        print("✅ [ValidationTests.testWeekdayFromString] Test completed")
    }
}