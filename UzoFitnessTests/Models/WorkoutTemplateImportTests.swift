import XCTest
import Foundation
@testable import UzoFitness

final class WorkoutTemplateImportTests: XCTestCase {
    
    var decoder: JSONDecoder!
    
    override func setUp() {
        super.setUp()
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }
    
    override func tearDown() {
        decoder = nil
        super.tearDown()
    }
    
    // MARK: - Valid JSON Tests
    
    func testValidWorkoutTemplateImport() throws {
        let validJSON = """
        {
            "name": "Push/Pull/Legs",
            "summary": "Classic 3-day split focusing on push, pull, and leg movements",
            "createdAt": "2024-01-01T00:00:00Z",
            "days": [
                {
                    "dayIndex": 1,
                    "name": "Push Day",
                    "exercises": [
                        {
                            "name": "Bench Press",
                            "sets": 4,
                            "reps": 8,
                            "weight": 185.5,
                            "supersetGroup": 1
                        },
                        {
                            "name": "Shoulder Press",
                            "sets": 3,
                            "reps": 10,
                            "weight": 135.0,
                            "supersetGroup": 1
                        }
                    ]
                }
            ]
        }
        """.data(using: .utf8)!
        
        let importDTO = try decoder.decode(WorkoutTemplateImportDTO.self, from: validJSON)
        
        // IDs should be auto-generated, not present in JSON
        XCTAssertEqual(importDTO.name, "Push/Pull/Legs")
        XCTAssertEqual(importDTO.summary, "Classic 3-day split focusing on push, pull, and leg movements")
        XCTAssertEqual(importDTO.days.count, 1)
        
        let firstDay = importDTO.days.first!
        XCTAssertEqual(firstDay.dayIndex, 1)
        XCTAssertEqual(firstDay.name, "Push Day")
        XCTAssertEqual(firstDay.exercises.count, 2)
        
        let firstExercise = firstDay.exercises.first!
        XCTAssertEqual(firstExercise.name, "Bench Press")
        XCTAssertEqual(firstExercise.sets, 4)
        XCTAssertEqual(firstExercise.reps, 8)
        XCTAssertEqual(firstExercise.weight, 185.5)
        XCTAssertEqual(firstExercise.supersetGroup, 1)
        
        // Should not throw when validating
        XCTAssertNoThrow(try importDTO.validate())
    }
    
    func testMinimalValidWorkoutTemplate() throws {
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
                            "sets": 3,
                            "reps": 10,
                            "weight": null
                        }
                    ]
                }
            ]
        }
        """.data(using: .utf8)!
        
        let importDTO = try decoder.decode(WorkoutTemplateImportDTO.self, from: minimalJSON)
        
        XCTAssertNil(importDTO.createdAt)
        XCTAssertEqual(importDTO.name, "Simple Workout")
        XCTAssertEqual(importDTO.summary, "")
        
        let exercise = importDTO.days.first!.exercises.first!
        XCTAssertNil(exercise.weight)
        XCTAssertNil(exercise.supersetGroup)
        
        // Should not throw when validating
        XCTAssertNoThrow(try importDTO.validate())
    }
    
    func testAutoIDGenerationTemplate() throws {
        let autoIDJSON = """
        {
            "name": "Auto-ID Test Template",
            "summary": "A 3-day template to test automatic ID generation",
            "days": [
                {
                    "dayIndex": 1,
                    "name": "Push Day",
                    "exercises": [
                        {
                            "name": "Bench Press",
                            "sets": 4,
                            "reps": 8,
                            "weight": 185.0
                        },
                        {
                            "name": "Overhead Press",
                            "sets": 3,
                            "reps": 10,
                            "weight": 95.0
                        },
                        {
                            "name": "Dips",
                            "sets": 3,
                            "reps": 12,
                            "supersetGroup": 1
                        },
                        {
                            "name": "Close Grip Push-ups",
                            "sets": 3,
                            "reps": 15,
                            "supersetGroup": 1
                        }
                    ]
                }
            ]
        }
        """.data(using: .utf8)!
        
        let importDTO = try decoder.decode(WorkoutTemplateImportDTO.self, from: autoIDJSON)
        
        XCTAssertEqual(importDTO.name, "Auto-ID Test Template")
        XCTAssertEqual(importDTO.days.count, 1)
        
        let firstDay = importDTO.days.first!
        XCTAssertEqual(firstDay.exercises.count, 4)
        
        // Check superset groups with numeric values
        XCTAssertNil(firstDay.exercises[0].supersetGroup)
        XCTAssertNil(firstDay.exercises[1].supersetGroup)
        XCTAssertEqual(firstDay.exercises[2].supersetGroup, 1)
        XCTAssertEqual(firstDay.exercises[3].supersetGroup, 1)
        
        // Should not throw when validating
        XCTAssertNoThrow(try importDTO.validate())
    }
    
    // MARK: - Validation Error Tests
    
    func testEmptyTemplateName() throws {
        let json = """
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
                            "sets": 3,
                            "reps": 10
                        }
                    ]
                }
            ]
        }
        """.data(using: .utf8)!
        
        let importDTO = try decoder.decode(WorkoutTemplateImportDTO.self, from: json)
        
        XCTAssertThrowsError(try importDTO.validate()) { error in
            guard let importError = error as? ImportError else {
                XCTFail("Expected ImportError")
                return
            }
            
            if case .emptyTemplateName = importError {
                // Expected error
            } else {
                XCTFail("Expected emptyTemplateName error, got \(importError)")
            }
        }
    }
    
    func testTemplateNameTooLong() throws {
        let longName = String(repeating: "a", count: 101)
        let json = """
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
                            "sets": 3,
                            "reps": 10
                        }
                    ]
                }
            ]
        }
        """.data(using: .utf8)!
        
        let importDTO = try decoder.decode(WorkoutTemplateImportDTO.self, from: json)
        
        XCTAssertThrowsError(try importDTO.validate()) { error in
            guard let importError = error as? ImportError else {
                XCTFail("Expected ImportError")
                return
            }
            
            if case .templateNameTooLong(let count) = importError {
                XCTAssertEqual(count, 101)
            } else {
                XCTFail("Expected templateNameTooLong error, got \(importError)")
            }
        }
    }
    
    func testNoDaysProvided() throws {
        let json = """
        {
            "name": "Empty Template",
            "summary": "Test",
            "days": []
        }
        """.data(using: .utf8)!
        
        let importDTO = try decoder.decode(WorkoutTemplateImportDTO.self, from: json)
        
        XCTAssertThrowsError(try importDTO.validate()) { error in
            guard let importError = error as? ImportError else {
                XCTFail("Expected ImportError")
                return
            }
            
            if case .noDaysProvided = importError {
                // Expected error
            } else {
                XCTFail("Expected noDaysProvided error, got \(importError)")
            }
        }
    }
    
    func testInvalidDayIndex() throws {
        let json = """
        {
            "name": "Test Template",
            "summary": "Test",
            "days": [
                {
                    "dayIndex": 8,
                    "name": "Invalid Day",
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
        """.data(using: .utf8)!
        
        let importDTO = try decoder.decode(WorkoutTemplateImportDTO.self, from: json)
        
        XCTAssertThrowsError(try importDTO.validate()) { error in
            guard let importError = error as? ImportError else {
                XCTFail("Expected ImportError")
                return
            }
            
            if case .dayValidationFailed(let dayIndex, let underlyingError) = importError {
                XCTAssertEqual(dayIndex, 0) // First day (0-indexed)
                
                if let underlying = underlyingError as? ImportError,
                   case .invalidDayIndex(let index) = underlying {
                    XCTAssertEqual(index, 8)
                } else {
                    XCTFail("Expected invalidDayIndex underlying error")
                }
            } else {
                XCTFail("Expected dayValidationFailed error, got \(importError)")
            }
        }
    }
    
    func testInvalidExerciseSets() throws {
        let json = """
        {
            "name": "Test Template",
            "summary": "Test",
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
        """.data(using: .utf8)!
        
        let importDTO = try decoder.decode(WorkoutTemplateImportDTO.self, from: json)
        
        XCTAssertThrowsError(try importDTO.validate()) { error in
            guard let importError = error as? ImportError else {
                XCTFail("Expected ImportError")
                return
            }
            
            if case .dayValidationFailed(_, let underlyingError) = importError {
                if let underlying = underlyingError as? ImportError,
                   case .exerciseValidationFailed(_, let exerciseError) = underlying {
                    if let exerciseErr = exerciseError as? ImportError,
                       case .invalidSets(let sets) = exerciseErr {
                        XCTAssertEqual(sets, 0)
                    } else {
                        XCTFail("Expected invalidSets error")
                    }
                } else {
                    XCTFail("Expected exerciseValidationFailed error")
                }
            } else {
                XCTFail("Expected dayValidationFailed error, got \(importError)")
            }
        }
    }
    
    func testInvalidSupersetGroup() throws {
        let json = """
        {
            "name": "Test Template",
            "summary": "Test",
            "days": [
                {
                    "dayIndex": 1,
                    "name": "Day 1",
                    "exercises": [
                        {
                            "name": "Push-ups",
                            "sets": 3,
                            "reps": 10,
                            "supersetGroup": 0
                        }
                    ]
                }
            ]
        }
        """.data(using: .utf8)!
        
        let importDTO = try decoder.decode(WorkoutTemplateImportDTO.self, from: json)
        
        XCTAssertThrowsError(try importDTO.validate()) { error in
            guard let importError = error as? ImportError else {
                XCTFail("Expected ImportError")
                return
            }
            
            if case .dayValidationFailed(_, let underlyingError) = importError {
                if let underlying = underlyingError as? ImportError,
                   case .exerciseValidationFailed(_, let exerciseError) = underlying {
                    if let exerciseErr = exerciseError as? ImportError,
                       case .invalidSupersetGroup(let group) = exerciseErr {
                        XCTAssertEqual(group, 0)
                    } else {
                        XCTFail("Expected invalidSupersetGroup error")
                    }
                } else {
                    XCTFail("Expected exerciseValidationFailed error")
                }
            } else {
                XCTFail("Expected dayValidationFailed error, got \(importError)")
            }
        }
    }
    
    // MARK: - JSON Decoding Error Tests
    
    func testMissingRequiredField() throws {
        let json = """
        {
            "summary": "Missing name field",
            "days": []
        }
        """.data(using: .utf8)!
        
        XCTAssertThrowsError(try decoder.decode(WorkoutTemplateImportDTO.self, from: json)) { error in
            XCTAssert(error is DecodingError)
        }
    }
    
    func testInvalidDataType() throws {
        let json = """
        {
            "name": "Test Template",
            "summary": "Test",
            "days": [
                {
                    "dayIndex": "invalid",
                    "name": "Day 1",
                    "exercises": []
                }
            ]
        }
        """.data(using: .utf8)!
        
        XCTAssertThrowsError(try decoder.decode(WorkoutTemplateImportDTO.self, from: json)) { error in
            XCTAssert(error is DecodingError)
        }
    }
    
    // MARK: - Round-trip Tests
    
    func testEncodeDecodeRoundTripWithoutIDs() throws {
        let originalDTO = WorkoutTemplateImportDTO(
            name: "Test Template",
            summary: "Round-trip test without IDs",
            createdAt: Date(),
            days: [
                DayImportDTO(
                    dayIndex: 1,
                    name: "Day 1",
                    exercises: [
                        ExerciseImportDTO(
                            name: "Push-ups",
                            sets: 3,
                            reps: 15,
                            weight: 45.0,
                            supersetGroup: 2
                        )
                    ]
                )
            ]
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let jsonData = try encoder.encode(originalDTO)
        let decodedDTO = try decoder.decode(WorkoutTemplateImportDTO.self, from: jsonData)
        
        XCTAssertEqual(originalDTO.name, decodedDTO.name)
        XCTAssertEqual(originalDTO.summary, decodedDTO.summary)
        XCTAssertEqual(originalDTO.days.count, decodedDTO.days.count)
        
        let originalDay = originalDTO.days.first!
        let decodedDay = decodedDTO.days.first!
        XCTAssertEqual(originalDay.dayIndex, decodedDay.dayIndex)
        XCTAssertEqual(originalDay.name, decodedDay.name)
        XCTAssertEqual(originalDay.exercises.count, decodedDay.exercises.count)
        
        let originalExercise = originalDay.exercises.first!
        let decodedExercise = decodedDay.exercises.first!
        XCTAssertEqual(originalExercise.name, decodedExercise.name)
        XCTAssertEqual(originalExercise.sets, decodedExercise.sets)
        XCTAssertEqual(originalExercise.reps, decodedExercise.reps)
        XCTAssertEqual(originalExercise.weight, decodedExercise.weight)
        XCTAssertEqual(originalExercise.supersetGroup, decodedExercise.supersetGroup)
        
        // Validation should pass
        XCTAssertNoThrow(try decodedDTO.validate())
    }
} 