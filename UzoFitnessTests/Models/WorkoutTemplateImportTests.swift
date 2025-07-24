import Foundation
import SwiftData
import Testing
import UzoFitnessCore
@testable import UzoFitness

/// Tests to verify workout template JSON import functionality
@MainActor
final class WorkoutTemplateImportTests {
    
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
    
    // MARK: - Valid Import Tests
    
    // Note: testValidWorkoutTemplateImport removed per user instruction - enum mapping issues
    
    @Test("Minimal valid workout template import")
    func testMinimalValidWorkoutTemplate() async throws {
        print("🔄 [WorkoutTemplateImportTests.testMinimalValidWorkoutTemplate] Starting test")
        
        setUp()
        defer { tearDown() }
        
        let minimalJSON = """
        {
            "name": "Simple Workout",
            "summary": "",
            "days": [
                {
                    "dayIndex": 1,
                    "name": "Day 1",
                    "exercises": [
                        {
                            "name": "Push-ups",
                            "sets": 1,
                            "reps": 1
                        }
                    ]
                }
            ]
        }
        """
        
        let jsonData = minimalJSON.data(using: .utf8)!
        let importDTO = try JSONDecoder().decode(WorkoutTemplateImportDTO.self, from: jsonData)
        
        // Verify minimal properties
        #expect(importDTO.name == "Simple Workout")
        #expect(importDTO.summary == "")
        #expect(importDTO.createdAt == nil)
        #expect(importDTO.days.count == 1)
        
        let day = importDTO.days[0]
        #expect(day.exercises.count == 1)
        
        let exercise = day.exercises[0]
        #expect(exercise.name == "Push-ups")
        #expect(exercise.sets == 1)
        #expect(exercise.reps == 1)
        #expect(exercise.weight == nil)
        #expect(exercise.supersetGroup == nil)
        
        // Should validate successfully
        #expect(throws: Never.self) {
            try importDTO.validate()
        }
        
        print("✅ [WorkoutTemplateImportTests.testMinimalValidWorkoutTemplate] Test completed")
    }
    
    @Test("Workout template with day names instead of indices")
    func testWorkoutTemplateWithDayNames() async throws {
        print("🔄 [WorkoutTemplateImportTests.testWorkoutTemplateWithDayNames] Starting test")
        
        setUp()
        defer { tearDown() }
        
        let dayNamesJSON = """
        {
            "name": "Weekly Routine",
            "summary": "Full week routine",
            "days": [
                {
                    "dayName": "Monday",
                    "name": "Upper Body",
                    "exercises": [
                        {
                            "name": "Bench Press",
                            "sets": 3,
                            "reps": 10,
                            "weight": 135.0
                        }
                    ]
                },
                {
                    "dayName": "wednesday",
                    "name": "Lower Body",
                    "exercises": [
                        {
                            "name": "Squats",
                            "sets": 3,
                            "reps": 12,
                            "weight": 185.0
                        }
                    ]
                }
            ]
        }
        """
        
        let jsonData = dayNamesJSON.data(using: .utf8)!
        let importDTO = try JSONDecoder().decode(WorkoutTemplateImportDTO.self, from: jsonData)
        
        // Verify day name parsing
        let mondayDay = importDTO.days[0]
        #expect(mondayDay.dayName == "Monday")
        #expect(mondayDay.weekday == .monday)
        
        let wednesdayDay = importDTO.days[1]
        #expect(wednesdayDay.dayName == "wednesday")
        #expect(wednesdayDay.weekday == .wednesday) // Should be case-insensitive
        
        // Should validate successfully
        #expect(throws: Never.self) {
            try importDTO.validate()
        }
        
        print("✅ [WorkoutTemplateImportTests.testWorkoutTemplateWithDayNames] Test completed")
    }
    
    // MARK: - Validation Error Tests
    
    @Test("Import validation fails for empty template name")
    func testImportValidationEmptyTemplateName() async throws {
        print("🔄 [WorkoutTemplateImportTests.testImportValidationEmptyTemplateName] Starting test")
        
        setUp()
        defer { tearDown() }
        
        let emptyNameJSON = """
        {
            "name": "",
            "summary": "Test",
            "days": [
                {
                    "dayIndex": 1,
                    "name": "Day 1",
                    "exercises": [
                        {
                            "name": "Push-ups",
                            "sets": 1,
                            "reps": 1
                        }
                    ]
                }
            ]
        }
        """
        
        let jsonData = emptyNameJSON.data(using: .utf8)!
        let importDTO = try JSONDecoder().decode(WorkoutTemplateImportDTO.self, from: jsonData)
        
        // Should fail validation
        #expect(throws: ImportError.self) {
            try importDTO.validate()
        }
        
        print("✅ [WorkoutTemplateImportTests.testImportValidationEmptyTemplateName] Test completed")
    }
    
    @Test("Import validation fails for template name too long")
    func testImportValidationTemplateNameTooLong() async throws {
        print("🔄 [WorkoutTemplateImportTests.testImportValidationTemplateNameTooLong] Starting test")
        
        setUp()
        defer { tearDown() }
        
        let longName = String(repeating: "a", count: 101)
        let longNameJSON = """
        {
            "name": "\(longName)",
            "summary": "Test",
            "days": [
                {
                    "dayIndex": 1,
                    "name": "Day 1",
                    "exercises": [
                        {
                            "name": "Push-ups",
                            "sets": 1,
                            "reps": 1
                        }
                    ]
                }
            ]
        }
        """
        
        let jsonData = longNameJSON.data(using: .utf8)!
        let importDTO = try JSONDecoder().decode(WorkoutTemplateImportDTO.self, from: jsonData)
        
        // Should fail validation
        #expect(throws: ImportError.self) {
            try importDTO.validate()
        }
        
        print("✅ [WorkoutTemplateImportTests.testImportValidationTemplateNameTooLong] Test completed")
    }
    
    @Test("Import validation fails for no days provided")
    func testImportValidationNoDays() async throws {
        print("🔄 [WorkoutTemplateImportTests.testImportValidationNoDays] Starting test")
        
        setUp()
        defer { tearDown() }
        
        let noDaysJSON = """
        {
            "name": "Empty Template",
            "summary": "No days",
            "days": []
        }
        """
        
        let jsonData = noDaysJSON.data(using: .utf8)!
        let importDTO = try JSONDecoder().decode(WorkoutTemplateImportDTO.self, from: jsonData)
        
        // Should fail validation
        #expect(throws: ImportError.self) {
            try importDTO.validate()
        }
        
        print("✅ [WorkoutTemplateImportTests.testImportValidationNoDays] Test completed")
    }
    
    @Test("Import validation fails for invalid day index")
    func testImportValidationInvalidDayIndex() async throws {
        print("🔄 [WorkoutTemplateImportTests.testImportValidationInvalidDayIndex] Starting test")
        
        setUp()
        defer { tearDown() }
        
        let invalidDayJSON = """
        {
            "name": "Invalid Day",
            "summary": "Bad day index",
            "days": [
                {
                    "dayIndex": 8,
                    "name": "Invalid Day",
                    "exercises": [
                        {
                            "name": "Push-ups",
                            "sets": 1,
                            "reps": 1
                        }
                    ]
                }
            ]
        }
        """
        
        let jsonData = invalidDayJSON.data(using: .utf8)!
        let importDTO = try JSONDecoder().decode(WorkoutTemplateImportDTO.self, from: jsonData)
        
        // Should fail validation
        #expect(throws: ImportError.self) {
            try importDTO.validate()
        }
        
        print("✅ [WorkoutTemplateImportTests.testImportValidationInvalidDayIndex] Test completed")
    }
    
    @Test("Import validation fails for invalid day name")
    func testImportValidationInvalidDayName() async throws {
        print("🔄 [WorkoutTemplateImportTests.testImportValidationInvalidDayName] Starting test")
        
        setUp()
        defer { tearDown() }
        
        let invalidDayNameJSON = """
        {
            "name": "Invalid Day Name",
            "summary": "Bad day name",
            "days": [
                {
                    "dayName": "Funday",
                    "name": "Invalid Day",
                    "exercises": [
                        {
                            "name": "Push-ups",
                            "sets": 1,
                            "reps": 1
                        }
                    ]
                }
            ]
        }
        """
        
        let jsonData = invalidDayNameJSON.data(using: .utf8)!
        let importDTO = try JSONDecoder().decode(WorkoutTemplateImportDTO.self, from: jsonData)
        
        // Should fail validation
        #expect(throws: ImportError.self) {
            try importDTO.validate()
        }
        
        print("✅ [WorkoutTemplateImportTests.testImportValidationInvalidDayName] Test completed")
    }
    
    @Test("Import validation fails for no exercises in day")
    func testImportValidationNoExercises() async throws {
        print("🔄 [WorkoutTemplateImportTests.testImportValidationNoExercises] Starting test")
        
        setUp()
        defer { tearDown() }
        
        let noExercisesJSON = """
        {
            "name": "Empty Day",
            "summary": "Day with no exercises",
            "days": [
                {
                    "dayIndex": 1,
                    "name": "Empty Day",
                    "exercises": []
                }
            ]
        }
        """
        
        let jsonData = noExercisesJSON.data(using: .utf8)!
        let importDTO = try JSONDecoder().decode(WorkoutTemplateImportDTO.self, from: jsonData)
        
        // Should fail validation
        #expect(throws: ImportError.self) {
            try importDTO.validate()
        }
        
        print("✅ [WorkoutTemplateImportTests.testImportValidationNoExercises] Test completed")
    }
    
    @Test("Import validation fails for invalid exercise parameters")
    func testImportValidationInvalidExerciseParameters() async throws {
        print("🔄 [WorkoutTemplateImportTests.testImportValidationInvalidExerciseParameters] Starting test")
        
        setUp()
        defer { tearDown() }
        
        // Test zero sets
        let zeroSetsJSON = """
        {
            "name": "Invalid Exercise",
            "summary": "Zero sets",
            "days": [
                {
                    "dayIndex": 1,
                    "name": "Day 1",
                    "exercises": [
                        {
                            "name": "Push-ups",
                            "sets": 0,
                            "reps": 10
                        }
                    ]
                }
            ]
        }
        """
        
        let zeroSetsData = zeroSetsJSON.data(using: .utf8)!
        let zeroSetsDTO = try JSONDecoder().decode(WorkoutTemplateImportDTO.self, from: zeroSetsData)
        
        #expect(throws: ImportError.self) {
            try zeroSetsDTO.validate()
        }
        
        // Test zero reps
        let zeroRepsJSON = """
        {
            "name": "Invalid Exercise",
            "summary": "Zero reps",
            "days": [
                {
                    "dayIndex": 1,
                    "name": "Day 1",
                    "exercises": [
                        {
                            "name": "Push-ups",
                            "sets": 3,
                            "reps": 0
                        }
                    ]
                }
            ]
        }
        """
        
        let zeroRepsData = zeroRepsJSON.data(using: .utf8)!
        let zeroRepsDTO = try JSONDecoder().decode(WorkoutTemplateImportDTO.self, from: zeroRepsData)
        
        #expect(throws: ImportError.self) {
            try zeroRepsDTO.validate()
        }
        
        // Test negative weight
        let negativeWeightJSON = """
        {
            "name": "Invalid Exercise",
            "summary": "Negative weight",
            "days": [
                {
                    "dayIndex": 1,
                    "name": "Day 1",
                    "exercises": [
                        {
                            "name": "Bench Press",
                            "sets": 3,
                            "reps": 10,
                            "weight": -50.0
                        }
                    ]
                }
            ]
        }
        """
        
        let negativeWeightData = negativeWeightJSON.data(using: .utf8)!
        let negativeWeightDTO = try JSONDecoder().decode(WorkoutTemplateImportDTO.self, from: negativeWeightData)
        
        #expect(throws: ImportError.self) {
            try negativeWeightDTO.validate()
        }
        
        print("✅ [WorkoutTemplateImportTests.testImportValidationInvalidExerciseParameters] Test completed")
    }
    
    // MARK: - JSON Error Handling Tests
    
    @Test("Import handles malformed JSON correctly")
    func testImportHandlesMalformedJSON() async throws {
        print("🔄 [WorkoutTemplateImportTests.testImportHandlesMalformedJSON] Starting test")
        
        setUp()
        defer { tearDown() }
        
        let malformedJSON = """
        {
            "name": "Test Template",
            "summary": "Malformed JSON",
            "days": [
                {
                    "dayIndex": 1,
                    "name": "Day 1",
                    "exercises": [
                        {
                            "name": "Push-ups",
                            "sets": "not a number",
                            "reps": 10
                        }
                    ]
                }
            ]
        """
        
        let jsonData = malformedJSON.data(using: .utf8)!
        
        // Should throw DecodingError
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(WorkoutTemplateImportDTO.self, from: jsonData)
        }
        
        print("✅ [WorkoutTemplateImportTests.testImportHandlesMalformedJSON] Test completed")
    }
    
    @Test("Import handles missing required fields")
    func testImportHandlesMissingRequiredFields() async throws {
        print("🔄 [WorkoutTemplateImportTests.testImportHandlesMissingRequiredFields] Starting test")
        
        setUp()
        defer { tearDown() }
        
        let missingFieldsJSON = """
        {
            "summary": "Missing name field",
            "days": [
                {
                    "dayIndex": 1,
                    "name": "Day 1",
                    "exercises": [
                        {
                            "name": "Push-ups",
                            "reps": 10
                        }
                    ]
                }
            ]
        }
        """
        
        let jsonData = missingFieldsJSON.data(using: .utf8)!
        
        // Should throw DecodingError for missing required field
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(WorkoutTemplateImportDTO.self, from: jsonData)
        }
        
        print("✅ [WorkoutTemplateImportTests.testImportHandlesMissingRequiredFields] Test completed")
    }
    
    // MARK: - Auto-ID Generation Tests
    
    @Test("Import handles missing day and exercise identifiers")
    func testImportAutoIDGeneration() async throws {
        print("🔄 [WorkoutTemplateImportTests.testImportAutoIDGeneration] Starting test")
        
        setUp()
        defer { tearDown() }
        
        let missingIdentifiersJSON = """
        {
            "name": "Auto ID Test",
            "summary": "Test auto ID generation",
            "days": [
                {
                    "name": "Day Without ID",
                    "exercises": [
                        {
                            "name": "Push-ups",
                            "sets": 3,
                            "reps": 10
                        }
                    ]
                }
            ]
        }
        """
        
        let jsonData = missingIdentifiersJSON.data(using: .utf8)!
        let importDTO = try JSONDecoder().decode(WorkoutTemplateImportDTO.self, from: jsonData)
        
        let day = importDTO.days[0]
        
        // Day should have no weekday since both dayIndex and dayName are missing
        #expect(day.weekday == nil)
        #expect(day.dayIndex == nil)
        #expect(day.dayName == nil)
        
        // Validation should fail due to missing day identifier
        #expect(throws: ImportError.self) {
            try importDTO.validate()
        }
        
        print("✅ [WorkoutTemplateImportTests.testImportAutoIDGeneration] Test completed")
    }
}