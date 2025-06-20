import XCTest
@testable import UzoFitness
import SwiftData

final class JSONImportTests: XCTestCase {
    
    func testExerciseJSONImport_WithMissingID() throws {
        // Given: JSON without ID field (typical import scenario)
        let jsonString = """
        [
            {
                "name": "Push-ups",
                "category": "strength",
                "instructions": "Start in a plank position with hands shoulder-width apart. Lower your body until your chest nearly touches the floor, then push back up.",
                "mediaAssetID": null
            },
            {
                "name": "Squats",
                "category": "strength", 
                "instructions": "Stand with feet shoulder-width apart. Lower your body as if sitting back into a chair, keeping your chest up and weight on your heels.",
                "mediaAssetID": null
            }
        ]
        """
        
        // When: Attempting to decode the JSON
        let jsonData = jsonString.data(using: .utf8)!
        
        // Then: Should decode successfully with auto-generated IDs
        XCTAssertNoThrow(try JSONDecoder().decode([Exercise].self, from: jsonData))
        
        let exercises = try JSONDecoder().decode([Exercise].self, from: jsonData)
        XCTAssertEqual(exercises.count, 2)
        
        // Verify first exercise
        let pushUps = exercises[0]
        XCTAssertEqual(pushUps.name, "Push-ups")
        XCTAssertEqual(pushUps.category, .strength)
        XCTAssertEqual(pushUps.instructions, "Start in a plank position with hands shoulder-width apart. Lower your body until your chest nearly touches the floor, then push back up.")
        XCTAssertNil(pushUps.mediaAssetID)
        XCTAssertNotNil(pushUps.id) // Should have auto-generated ID
        
        // Verify second exercise  
        let squats = exercises[1]
        XCTAssertEqual(squats.name, "Squats")
        XCTAssertEqual(squats.category, .strength)
        XCTAssertEqual(squats.instructions, "Stand with feet shoulder-width apart. Lower your body as if sitting back into a chair, keeping your chest up and weight on your heels.")
        XCTAssertNil(squats.mediaAssetID)
        XCTAssertNotNil(squats.id) // Should have auto-generated ID
        
        // IDs should be different
        XCTAssertNotEqual(pushUps.id, squats.id)
    }
    
    func testExerciseJSONImport_WithExistingID() throws {
        // Given: JSON with existing ID field
        let existingID = UUID()
        let jsonString = """
        [
            {
                "id": "\(existingID.uuidString)",
                "name": "Burpees",
                "category": "cardio",
                "instructions": "From standing, squat down and place hands on floor. Jump feet back to plank, do push-up, jump feet forward, then jump up.",
                "mediaAssetID": "burpee-video-001"
            }
        ]
        """
        
        // When: Attempting to decode the JSON
        let jsonData = jsonString.data(using: .utf8)!
        let exercises = try JSONDecoder().decode([Exercise].self, from: jsonData)
        
        // Then: Should preserve the existing ID
        XCTAssertEqual(exercises.count, 1)
        let burpees = exercises[0]
        XCTAssertEqual(burpees.id, existingID)
        XCTAssertEqual(burpees.name, "Burpees")
        XCTAssertEqual(burpees.category, .cardio)
        XCTAssertEqual(burpees.mediaAssetID, "burpee-video-001")
    }
    
    @MainActor
    func testLibraryViewModel_ImportExercises() throws {
        // Given: A test model context
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Exercise.self, configurations: config)
        let context = ModelContext(container)
        
        let viewModel = LibraryViewModel(modelContext: context)
        
        let jsonString = """
        [
            {
                "name": "Mountain Climbers",
                "category": "cardio",
                "instructions": "Start in plank position. Alternate bringing knees to chest rapidly.",
                "mediaAssetID": null
            }
        ]
        """
        
        let jsonData = jsonString.data(using: .utf8)!
        
        // When: Importing exercises
        XCTAssertNoThrow(try viewModel.importExercises(from: jsonData))
        
        // Then: Should have imported successfully without errors
        XCTAssertNil(viewModel.importErrorMessage)
        print("✅ JSON import test completed successfully")
    }
    
    @MainActor
    func testLibraryViewModel_ImportExercises_WithError() throws {
        // Given: A test model context
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Exercise.self, configurations: config)
        let context = ModelContext(container)
        
        let viewModel = LibraryViewModel(modelContext: context)
        
        // Invalid JSON (missing required field)
        let invalidJsonString = """
        [
            {
                "name": "Invalid Exercise"
                // Missing category field
            }
        ]
        """
        
        let invalidJsonData = invalidJsonString.data(using: .utf8)!
        
        // When: Attempting to import invalid JSON
        XCTAssertThrowsError(try viewModel.importExercises(from: invalidJsonData)) { error in
            // Then: Should throw a decoding error
            XCTAssertTrue(error is DecodingError)
            
            // Verify it's specifically a missing key error
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, _):
                    print("❌ Missing required field: \(key.stringValue)")
                    XCTAssertEqual(key.stringValue, "category")
                default:
                    print("❌ Other decoding error: \(decodingError)")
                }
            }
        }
        
        print("✅ JSON import error handling test completed successfully")
    }
} 