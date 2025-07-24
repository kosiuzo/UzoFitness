import Foundation
import SwiftData
import Testing
import UzoFitnessCore
@testable import UzoFitness

/// Tests to verify Exercise model JSON import functionality and ID handling
@MainActor
final class JSONImportTests {
    
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
    
    // MARK: - Exercise JSON Import Tests
    
    @Test("Exercise JSON import with missing ID generates new UUID")
    func testExerciseJSONImport_WithMissingID() async throws {
        print("🔄 [JSONImportTests.testExerciseJSONImport_WithMissingID] Starting test")
        
        setUp()
        defer { tearDown() }
        
        let jsonWithoutID = """
        {
            "name": "Push-ups",
            "category": "strength",
            "instructions": "Standard push-up exercise",
            "mediaAssetID": "pushup_demo"
        }
        """
        
        let jsonData = jsonWithoutID.data(using: .utf8)!
        
        // Test JSON decoding without ID
        let decodedExercise = try JSONDecoder().decode(Exercise.self, from: jsonData)
        
        // Verify basic properties
        #expect(decodedExercise.name == "Push-ups")
        #expect(decodedExercise.category == .strength)
        #expect(decodedExercise.instructions == "Standard push-up exercise")
        #expect(decodedExercise.mediaAssetID == "pushup_demo")
        
        // Verify ID was auto-generated (not nil and is valid UUID)
        #expect(decodedExercise.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
        
        // Verify cached values are reset to nil
        #expect(decodedExercise.lastUsedWeight == nil)
        #expect(decodedExercise.lastUsedReps == nil)
        #expect(decodedExercise.lastTotalVolume == nil)
        #expect(decodedExercise.lastUsedDate == nil)
        
        // Verify relationships are initialized as empty
        #expect(decodedExercise.completedSets.isEmpty)
        #expect(decodedExercise.performedRecords.isEmpty)
        
        print("✅ [JSONImportTests.testExerciseJSONImport_WithMissingID] Test completed")
    }
    
    @Test("Exercise JSON import with existing ID preserves the ID")
    func testExerciseJSONImport_WithExistingID() async throws {
        print("🔄 [JSONImportTests.testExerciseJSONImport_WithExistingID] Starting test")
        
        setUp()
        defer { tearDown() }
        
        let expectedID = UUID()
        let jsonWithID = """
        {
            "id": "\(expectedID.uuidString)",
            "name": "Squats", 
            "category": "strength",
            "instructions": "Bodyweight squat exercise",
            "mediaAssetID": null
        }
        """
        
        let jsonData = jsonWithID.data(using: .utf8)!
        
        // Test JSON decoding with existing ID
        let decodedExercise = try JSONDecoder().decode(Exercise.self, from: jsonData)
        
        // Verify the ID was preserved
        #expect(decodedExercise.id == expectedID)
        
        // Verify other properties
        #expect(decodedExercise.name == "Squats")
        #expect(decodedExercise.category == .strength)
        #expect(decodedExercise.instructions == "Bodyweight squat exercise")
        #expect(decodedExercise.mediaAssetID == nil)
        
        // Verify cached values are reset to nil
        #expect(decodedExercise.lastUsedWeight == nil)
        #expect(decodedExercise.lastUsedReps == nil)
        #expect(decodedExercise.lastTotalVolume == nil)
        #expect(decodedExercise.lastUsedDate == nil)
        
        print("✅ [JSONImportTests.testExerciseJSONImport_WithExistingID] Test completed")
    }
    
    @Test("Exercise JSON import with all exercise categories")
    func testExerciseJSONImport_AllCategories() async throws {
        print("🔄 [JSONImportTests.testExerciseJSONImport_AllCategories] Starting test")
        
        setUp()
        defer { tearDown() }
        
        let categories: [ExerciseCategory] = [.strength, .cardio, .mobility, .balance]
        
        for category in categories {
            let jsonString = """
            {
                "name": "\(category.rawValue.capitalized) Exercise",
                "category": "\(category.rawValue)",
                "instructions": "Test instructions for \(category.rawValue)"
            }
            """
            
            let jsonData = jsonString.data(using: .utf8)!
            let decodedExercise = try JSONDecoder().decode(Exercise.self, from: jsonData)
            
            #expect(decodedExercise.category == category)
            #expect(decodedExercise.name == "\(category.rawValue.capitalized) Exercise")
            #expect(decodedExercise.instructions == "Test instructions for \(category.rawValue)")
        }
        
        print("✅ [JSONImportTests.testExerciseJSONImport_AllCategories] Test completed")
    }
    
    @Test("Exercise JSON import with minimal data")
    func testExerciseJSONImport_MinimalData() async throws {
        print("🔄 [JSONImportTests.testExerciseJSONImport_MinimalData] Starting test")
        
        setUp()
        defer { tearDown() }
        
        let minimalJSON = """
        {
            "name": "Simple Exercise",
            "category": "cardio", 
            "instructions": ""
        }
        """
        
        let jsonData = minimalJSON.data(using: .utf8)!
        let decodedExercise = try JSONDecoder().decode(Exercise.self, from: jsonData)
        
        // Verify minimal data is handled correctly
        #expect(decodedExercise.name == "Simple Exercise")
        #expect(decodedExercise.category == .cardio)
        #expect(decodedExercise.instructions == "")
        #expect(decodedExercise.mediaAssetID == nil)
        
        // Verify ID was auto-generated
        #expect(decodedExercise.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
        
        print("✅ [JSONImportTests.testExerciseJSONImport_MinimalData] Test completed")
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Exercise JSON import handles malformed JSON")
    func testExerciseJSONImport_MalformedJSON() async throws {
        print("🔄 [JSONImportTests.testExerciseJSONImport_MalformedJSON] Starting test")
        
        setUp()
        defer { tearDown() }
        
        let malformedJSON = """
        {
            "name": "Test Exercise",
            "category": "invalid_category",
            "instructions": "Test instructions"
        """
        
        let jsonData = malformedJSON.data(using: .utf8)!
        
        // Should throw DecodingError due to missing closing brace
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Exercise.self, from: jsonData)
        }
        
        print("✅ [JSONImportTests.testExerciseJSONImport_MalformedJSON] Test completed")
    }
    
    @Test("Exercise JSON import handles invalid category")
    func testExerciseJSONImport_InvalidCategory() async throws {
        print("🔄 [JSONImportTests.testExerciseJSONImport_InvalidCategory] Starting test")
        
        setUp()
        defer { tearDown() }
        
        let invalidCategoryJSON = """
        {
            "name": "Test Exercise",
            "category": "invalid_category",
            "instructions": "Test instructions"
        }
        """
        
        let jsonData = invalidCategoryJSON.data(using: .utf8)!
        
        // Should throw DecodingError due to invalid category
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Exercise.self, from: jsonData)
        }
        
        print("✅ [JSONImportTests.testExerciseJSONImport_InvalidCategory] Test completed")
    }
    
    @Test("Exercise JSON import handles missing required fields")
    func testExerciseJSONImport_MissingRequiredFields() async throws {
        print("🔄 [JSONImportTests.testExerciseJSONImport_MissingRequiredFields] Starting test")
        
        setUp()
        defer { tearDown() }
        
        // Missing name field
        let missingNameJSON = """
        {
            "category": "strength",
            "instructions": "Test instructions"
        }
        """
        
        let jsonData1 = missingNameJSON.data(using: .utf8)!
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Exercise.self, from: jsonData1)
        }
        
        // Missing category field  
        let missingCategoryJSON = """
        {
            "name": "Test Exercise",
            "instructions": "Test instructions"
        }
        """
        
        let jsonData2 = missingCategoryJSON.data(using: .utf8)!
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Exercise.self, from: jsonData2)
        }
        
        // Missing instructions field
        let missingInstructionsJSON = """
        {
            "name": "Test Exercise",
            "category": "strength"
        }
        """
        
        let jsonData3 = missingInstructionsJSON.data(using: .utf8)!
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Exercise.self, from: jsonData3)
        }
        
        print("✅ [JSONImportTests.testExerciseJSONImport_MissingRequiredFields] Test completed")
    }
    
    @Test("Exercise JSON import handles invalid UUID format")
    func testExerciseJSONImport_InvalidUUIDFormat() async throws {
        print("🔄 [JSONImportTests.testExerciseJSONImport_InvalidUUIDFormat] Starting test")
        
        setUp()
        defer { tearDown() }
        
        let invalidUUIDJSON = """
        {
            "id": "not-a-valid-uuid",
            "name": "Test Exercise",
            "category": "strength",
            "instructions": "Test instructions"
        }
        """
        
        let jsonData = invalidUUIDJSON.data(using: .utf8)!
        
        // Should throw DecodingError due to invalid UUID format
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Exercise.self, from: jsonData)
        }
        
        print("✅ [JSONImportTests.testExerciseJSONImport_InvalidUUIDFormat] Test completed")
    }
    
    // MARK: - Round-trip Encoding/Decoding Tests
    
    @Test("Exercise JSON round-trip encoding and decoding")
    func testExerciseJSONRoundTrip() async throws {
        print("🔄 [JSONImportTests.testExerciseJSONRoundTrip] Starting test")
        
        setUp()
        defer { tearDown() }
        
        // Create original exercise
        let originalExercise = TestHelpers.createTestExercise(
            name: "Deadlift",
            category: .strength,
            instructions: "Compound exercise targeting posterior chain"
        )
        originalExercise.mediaAssetID = "deadlift_demo"
        
        // Encode to JSON
        let encodedData = try JSONEncoder().encode(originalExercise)
        
        // Decode back from JSON
        let decodedExercise = try JSONDecoder().decode(Exercise.self, from: encodedData)
        
        // Verify all properties match
        #expect(decodedExercise.id == originalExercise.id)
        #expect(decodedExercise.name == originalExercise.name)
        #expect(decodedExercise.category == originalExercise.category)
        #expect(decodedExercise.instructions == originalExercise.instructions)
        #expect(decodedExercise.mediaAssetID == originalExercise.mediaAssetID)
        
        // Note: Cached values are not included in Codable, so they should be nil
        #expect(decodedExercise.lastUsedWeight == nil)
        #expect(decodedExercise.lastUsedReps == nil)
        #expect(decodedExercise.lastTotalVolume == nil)
        #expect(decodedExercise.lastUsedDate == nil)
        
        print("✅ [JSONImportTests.testExerciseJSONRoundTrip] Test completed")
    }
    
    @Test("Exercise JSON array import and export")
    func testExerciseJSONArrayImportExport() async throws {
        print("🔄 [JSONImportTests.testExerciseJSONArrayImportExport] Starting test")
        
        setUp()
        defer { tearDown() }
        
        let exercisesJSON = """
        [
            {
                "name": "Push-ups",
                "category": "strength",
                "instructions": "Upper body exercise",
                "mediaAssetID": "pushup_demo"
            },
            {
                "name": "Running",
                "category": "cardio", 
                "instructions": "Cardiovascular exercise"
            },
            {
                "name": "Yoga Flow",
                "category": "mobility",
                "instructions": "Flexibility exercise",
                "mediaAssetID": null
            }
        ]
        """
        
        let jsonData = exercisesJSON.data(using: .utf8)!
        
        // Test decoding array of exercises
        let exercises = try JSONDecoder().decode([Exercise].self, from: jsonData)
        
        // Verify array was decoded correctly
        #expect(exercises.count == 3)
        
        // Verify first exercise
        #expect(exercises[0].name == "Push-ups")
        #expect(exercises[0].category == .strength)
        #expect(exercises[0].mediaAssetID == "pushup_demo")
        
        // Verify second exercise
        #expect(exercises[1].name == "Running")
        #expect(exercises[1].category == .cardio)
        #expect(exercises[1].mediaAssetID == nil)
        
        // Verify third exercise
        #expect(exercises[2].name == "Yoga Flow")
        #expect(exercises[2].category == .mobility)
        #expect(exercises[2].mediaAssetID == nil)
        
        // Test encoding array back to JSON
        let encodedData = try JSONEncoder().encode(exercises)
        let reDecodedExercises = try JSONDecoder().decode([Exercise].self, from: encodedData)
        
        // Verify round-trip consistency
        #expect(reDecodedExercises.count == exercises.count)
        for (original, decoded) in zip(exercises, reDecodedExercises) {
            #expect(decoded.id == original.id)
            #expect(decoded.name == original.name)
            #expect(decoded.category == original.category)
        }
        
        print("✅ [JSONImportTests.testExerciseJSONArrayImportExport] Test completed")
    }
    
    // MARK: - ID Uniqueness Tests
    
    @Test("Exercise JSON import generates unique IDs for each exercise")
    func testExerciseJSONImport_UniqueIDGeneration() async throws {
        print("🔄 [JSONImportTests.testExerciseJSONImport_UniqueIDGeneration] Starting test")
        
        setUp()
        defer { tearDown() }
        
        let duplicateExercisesJSON = """
        [
            {
                "name": "Exercise 1",
                "category": "strength",
                "instructions": "First exercise"
            },
            {
                "name": "Exercise 2", 
                "category": "strength",
                "instructions": "Second exercise"
            },
            {
                "name": "Exercise 3",
                "category": "strength", 
                "instructions": "Third exercise"
            }
        ]
        """
        
        let jsonData = duplicateExercisesJSON.data(using: .utf8)!
        let exercises = try JSONDecoder().decode([Exercise].self, from: jsonData)
        
        // Verify all IDs are unique
        let ids = exercises.map { $0.id }
        let uniqueIds = Set(ids)
        
        #expect(ids.count == uniqueIds.count) // All IDs should be unique
        #expect(exercises.count == 3)
        
        // Verify each exercise has a valid UUID
        for exercise in exercises {
            #expect(exercise.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
        }
        
        print("✅ [JSONImportTests.testExerciseJSONImport_UniqueIDGeneration] Test completed")
    }
}