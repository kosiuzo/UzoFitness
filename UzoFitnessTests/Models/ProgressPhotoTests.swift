import Foundation
import SwiftData
import Testing
import UzoFitnessCore
@testable import UzoFitness

/// Tests to verify ProgressPhoto model persistence, initialization, and Codable functionality
@MainActor
final class ProgressPhotoTests {
    
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
    
    // MARK: - Initialization Tests
    
    @Test("ProgressPhoto initializer sets all properties correctly")
    func testInitializerSetsAllProperties() async throws {
        print("🔄 [ProgressPhotoTests.testInitializerSetsAllProperties] Starting test")
        
        setUp()
        defer { tearDown() }
        
        let testDate = Date()
        let testCreatedAt = Date().addingTimeInterval(-3600) // 1 hour ago
        let testWeightUUID = UUID()
        let testAssetIdentifier = "test_asset_123"
        let testNotes = "Great progress photo"
        let testManualWeight = 175.5
        
        // Test full initialization
        let progressPhoto = ProgressPhoto(
            date: testDate,
            angle: .front,
            assetIdentifier: testAssetIdentifier,
            weightSampleUUID: testWeightUUID,
            notes: testNotes,
            manualWeight: testManualWeight,
            createdAt: testCreatedAt
        )
        
        // Verify all properties are set correctly
        #expect(progressPhoto.date == testDate)
        #expect(progressPhoto.angle == .front)
        #expect(progressPhoto.assetIdentifier == testAssetIdentifier)
        #expect(progressPhoto.weightSampleUUID == testWeightUUID)
        #expect(progressPhoto.notes == testNotes)
        #expect(progressPhoto.manualWeight == testManualWeight)
        #expect(progressPhoto.createdAt == testCreatedAt)
        
        // Verify ID is generated (not nil and is valid UUID)
        #expect(progressPhoto.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
        
        print("✅ [ProgressPhotoTests.testInitializerSetsAllProperties] Test completed")
    }
    
    @Test("ProgressPhoto initializer with default values")
    func testInitializerWithDefaults() async throws {
        print("🔄 [ProgressPhotoTests.testInitializerWithDefaults] Starting test")
        
        setUp()
        defer { tearDown() }
        
        let testDate = Date()
        let testAssetIdentifier = "minimal_asset"
        let beforeCreation = Date()
        
        // Test minimal initialization with defaults
        let progressPhoto = ProgressPhoto(
            date: testDate,
            angle: .side,
            assetIdentifier: testAssetIdentifier
        )
        
        let afterCreation = Date()
        
        // Verify required properties
        #expect(progressPhoto.date == testDate)
        #expect(progressPhoto.angle == .side)
        #expect(progressPhoto.assetIdentifier == testAssetIdentifier)
        
        // Verify default values
        #expect(progressPhoto.weightSampleUUID == nil)
        #expect(progressPhoto.notes == "")
        #expect(progressPhoto.manualWeight == nil)
        
        // Verify ID is generated
        #expect(progressPhoto.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
        
        // Verify createdAt is set to current time (within reasonable range)
        #expect(progressPhoto.createdAt >= beforeCreation)
        #expect(progressPhoto.createdAt <= afterCreation)
        
        print("✅ [ProgressPhotoTests.testInitializerWithDefaults] Test completed")
    }
    
    @Test("ProgressPhoto supports all photo angles")
    func testAllPhotoAngles() async throws {
        print("🔄 [ProgressPhotoTests.testAllPhotoAngles] Starting test")
        
        setUp()
        defer { tearDown() }
        
        let testDate = Date()
        let angles: [PhotoAngle] = [.front, .side, .back]
        
        for angle in angles {
            let progressPhoto = ProgressPhoto(
                date: testDate,
                angle: angle,
                assetIdentifier: "test_\(angle.rawValue)"
            )
            
            #expect(progressPhoto.angle == angle)
            #expect(progressPhoto.assetIdentifier == "test_\(angle.rawValue)")
            
            // Verify display names
            switch angle {
            case .front:
                #expect(angle.displayName == "Front")
            case .side:
                #expect(angle.displayName == "Side")
            case .back:
                #expect(angle.displayName == "Back")
            }
        }
        
        print("✅ [ProgressPhotoTests.testAllPhotoAngles] Test completed")
    }
    
    // MARK: - SwiftData Persistence Tests
    
    @Test("Insert and fetch progress photo from SwiftData")
    func testInsertAndFetchProgressPhoto() async throws {
        print("🔄 [ProgressPhotoTests.testInsertAndFetchProgressPhoto] Starting test")
        
        setUp()
        defer { tearDown() }
        
        let testDate = Date()
        let testAssetIdentifier = "persistent_asset_456"
        let testNotes = "Persistence test photo"
        let testManualWeight = 180.0
        let testWeightUUID = UUID()
        
        // Create progress photo
        let originalPhoto = ProgressPhoto(
            date: testDate,
            angle: .back,
            assetIdentifier: testAssetIdentifier,
            weightSampleUUID: testWeightUUID,
            notes: testNotes,
            manualWeight: testManualWeight
        )
        
        // Insert into persistence context
        persistenceController.create(originalPhoto)
        
        // Fetch all progress photos
        let fetchedPhotos = persistenceController.fetch(ProgressPhoto.self)
        
        // Verify one photo was inserted
        #expect(fetchedPhotos.count == 1)
        
        let fetchedPhoto = fetchedPhotos[0]
        
        // Verify all properties match
        #expect(fetchedPhoto.id == originalPhoto.id)
        #expect(fetchedPhoto.date == originalPhoto.date)
        #expect(fetchedPhoto.angle == originalPhoto.angle)
        #expect(fetchedPhoto.assetIdentifier == originalPhoto.assetIdentifier)
        #expect(fetchedPhoto.weightSampleUUID == originalPhoto.weightSampleUUID)
        #expect(fetchedPhoto.notes == originalPhoto.notes)
        #expect(fetchedPhoto.manualWeight == originalPhoto.manualWeight)
        #expect(fetchedPhoto.createdAt == originalPhoto.createdAt)
        
        print("✅ [ProgressPhotoTests.testInsertAndFetchProgressPhoto] Test completed")
    }
    
    @Test("Insert multiple progress photos with different angles")
    func testInsertMultipleProgressPhotos() async throws {
        print("🔄 [ProgressPhotoTests.testInsertMultipleProgressPhotos] Starting test")
        
        setUp()
        defer { tearDown() }
        
        let baseDate = Date()
        let photos = [
            ProgressPhoto(
                date: baseDate,
                angle: .front,
                assetIdentifier: "front_photo",
                notes: "Front view"
            ),
            ProgressPhoto(
                date: baseDate.addingTimeInterval(60), // 1 minute later
                angle: .side,
                assetIdentifier: "side_photo", 
                notes: "Side view"
            ),
            ProgressPhoto(
                date: baseDate.addingTimeInterval(120), // 2 minutes later
                angle: .back,
                assetIdentifier: "back_photo",
                notes: "Back view"
            )
        ]
        
        // Insert all photos
        for photo in photos {
            persistenceController.create(photo)
        }
        
        // Fetch all photos
        let fetchedPhotos = persistenceController.fetch(ProgressPhoto.self)
        
        // Verify count
        #expect(fetchedPhotos.count == 3)
        
        // Verify each angle is represented
        let angles = Set(fetchedPhotos.map { $0.angle })
        #expect(angles.count == 3)
        #expect(angles.contains(.front))
        #expect(angles.contains(.side))
        #expect(angles.contains(.back))
        
        // Verify unique IDs
        let ids = Set(fetchedPhotos.map { $0.id })
        #expect(ids.count == 3) // All IDs should be unique
        
        print("✅ [ProgressPhotoTests.testInsertMultipleProgressPhotos] Test completed")
    }
    
    @Test("Update progress photo properties")
    func testUpdateProgressPhotoProperties() async throws {
        print("🔄 [ProgressPhotoTests.testUpdateProgressPhotoProperties] Starting test")
        
        setUp()
        defer { tearDown() }
        
        // Create and insert original photo
        let originalPhoto = ProgressPhoto(
            date: Date(),
            angle: .front,
            assetIdentifier: "original_asset",
            notes: "Original notes"
        )
        
        persistenceController.create(originalPhoto)
        
        // Fetch the photo
        let fetchedPhotos = persistenceController.fetch(ProgressPhoto.self)
        #expect(fetchedPhotos.count == 1)
        
        let photoToUpdate = fetchedPhotos[0]
        
        // Update properties
        photoToUpdate.notes = "Updated notes"
        photoToUpdate.manualWeight = 185.0
        photoToUpdate.weightSampleUUID = UUID()
        
        // Save changes
        persistenceController.save()
        
        // Fetch again to verify updates
        let updatedPhotos = persistenceController.fetch(ProgressPhoto.self)
        #expect(updatedPhotos.count == 1)
        
        let updatedPhoto = updatedPhotos[0]
        
        // Verify updates
        #expect(updatedPhoto.id == originalPhoto.id) // ID should remain the same
        #expect(updatedPhoto.notes == "Updated notes")
        #expect(updatedPhoto.manualWeight == 185.0)
        #expect(updatedPhoto.weightSampleUUID != nil)
        
        // Original properties should remain unchanged
        #expect(updatedPhoto.angle == .front)
        #expect(updatedPhoto.assetIdentifier == "original_asset")
        
        print("✅ [ProgressPhotoTests.testUpdateProgressPhotoProperties] Test completed")
    }
    
    @Test("Delete progress photo from SwiftData")
    func testDeleteProgressPhoto() async throws {
        print("🔄 [ProgressPhotoTests.testDeleteProgressPhoto] Starting test")
        
        setUp()
        defer { tearDown() }
        
        // Create and insert photo
        let progressPhoto = ProgressPhoto(
            date: Date(),
            angle: .side,
            assetIdentifier: "to_be_deleted"
        )
        
        persistenceController.create(progressPhoto)
        
        // Verify insertion
        let fetchedPhotos = persistenceController.fetch(ProgressPhoto.self)
        #expect(fetchedPhotos.count == 1)
        
        // Delete the photo
        persistenceController.delete(fetchedPhotos[0])
        
        // Verify deletion
        let remainingPhotos = persistenceController.fetch(ProgressPhoto.self)
        #expect(remainingPhotos.count == 0)
        
        print("✅ [ProgressPhotoTests.testDeleteProgressPhoto] Test completed")
    }
    
    // MARK: - Codable Implementation Tests
    
    @Test("ProgressPhoto JSON encoding and decoding")
    func testProgressPhotoJSONEncodingDecoding() async throws {
        print("🔄 [ProgressPhotoTests.testProgressPhotoJSONEncodingDecoding] Starting test")
        
        setUp()
        defer { tearDown() }
        
        let testDate = Date()
        let testCreatedAt = Date().addingTimeInterval(-1800) // 30 minutes ago
        let testWeightUUID = UUID()
        
        // Create original progress photo
        let originalPhoto = ProgressPhoto(
            date: testDate,
            angle: .front,
            assetIdentifier: "codable_test_asset",
            weightSampleUUID: testWeightUUID,
            notes: "Codable test photo",
            manualWeight: 172.5,
            createdAt: testCreatedAt
        )
        
        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let encodedData = try encoder.encode(originalPhoto)
        
        // Decode from JSON
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedPhoto = try decoder.decode(ProgressPhoto.self, from: encodedData)
        
        // Verify all properties match (excluding dates which may have precision issues)
        #expect(decodedPhoto.id == originalPhoto.id)
        #expect(decodedPhoto.angle == originalPhoto.angle)
        #expect(decodedPhoto.assetIdentifier == originalPhoto.assetIdentifier)
        #expect(decodedPhoto.weightSampleUUID == originalPhoto.weightSampleUUID)
        #expect(decodedPhoto.notes == originalPhoto.notes)
        #expect(decodedPhoto.manualWeight == originalPhoto.manualWeight)
        
        // Verify date fields are present and reasonable (within a few seconds)
        #expect(abs(decodedPhoto.date.timeIntervalSince1970 - originalPhoto.date.timeIntervalSince1970) < 5.0)
        #expect(abs(decodedPhoto.createdAt.timeIntervalSince1970 - originalPhoto.createdAt.timeIntervalSince1970) < 5.0)
        
        print("✅ [ProgressPhotoTests.testProgressPhotoJSONEncodingDecoding] Test completed")
    }
    
    @Test("ProgressPhoto JSON encoding with optional values")
    func testProgressPhotoJSONEncodingWithOptionals() async throws {
        print("🔄 [ProgressPhotoTests.testProgressPhotoJSONEncodingWithOptionals] Starting test")
        
        setUp()
        defer { tearDown() }
        
        // Create progress photo with nil optional values
        let photoWithNils = ProgressPhoto(
            date: Date(),
            angle: .back,
            assetIdentifier: "optional_test_asset",
            weightSampleUUID: nil, // nil optional
            notes: "",
            manualWeight: nil // nil optional
        )
        
        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let encodedData = try encoder.encode(photoWithNils)
        
        // Decode from JSON
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedPhoto = try decoder.decode(ProgressPhoto.self, from: encodedData)
        
        // Verify optional values are handled correctly
        #expect(decodedPhoto.weightSampleUUID == nil)
        #expect(decodedPhoto.manualWeight == nil)
        #expect(decodedPhoto.notes == "")
        
        // Verify other properties
        #expect(decodedPhoto.id == photoWithNils.id)
        #expect(decodedPhoto.angle == .back)
        #expect(decodedPhoto.assetIdentifier == "optional_test_asset")
        
        print("✅ [ProgressPhotoTests.testProgressPhotoJSONEncodingWithOptionals] Test completed")
    }
    
    @Test("ProgressPhoto JSON decoding handles all photo angles")
    func testProgressPhotoJSONDecodingAllAngles() async throws {
        print("🔄 [ProgressPhotoTests.testProgressPhotoJSONDecodingAllAngles] Starting test")
        
        setUp()
        defer { tearDown() }
        
        let angles: [PhotoAngle] = [.front, .side, .back]
        
        for angle in angles {
            let jsonString = """
            {
                "id": "\(UUID().uuidString)",
                "date": "2025-01-15T12:00:00Z",
                "angle": "\(angle.rawValue)",
                "assetIdentifier": "test_\(angle.rawValue)_asset",
                "notes": "Test \(angle.displayName) photo",
                "createdAt": "2025-01-15T11:30:00Z"
            }
            """
            
            let jsonData = jsonString.data(using: .utf8)!
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let decodedPhoto = try decoder.decode(ProgressPhoto.self, from: jsonData)
            
            // Verify angle was decoded correctly
            #expect(decodedPhoto.angle == angle)
            #expect(decodedPhoto.assetIdentifier == "test_\(angle.rawValue)_asset")
            #expect(decodedPhoto.notes == "Test \(angle.displayName) photo")
            
            // Verify optional values are nil when not provided
            #expect(decodedPhoto.weightSampleUUID == nil)
            #expect(decodedPhoto.manualWeight == nil)
        }
        
        print("✅ [ProgressPhotoTests.testProgressPhotoJSONDecodingAllAngles] Test completed")
    }
    
    @Test("ProgressPhoto JSON array encoding and decoding")
    func testProgressPhotoJSONArrayEncodingDecoding() async throws {
        print("🔄 [ProgressPhotoTests.testProgressPhotoJSONArrayEncodingDecoding] Starting test")
        
        setUp()
        defer { tearDown() }
        
        let baseDate = Date()
        
        // Create array of progress photos
        let originalPhotos = [
            ProgressPhoto(
                date: baseDate,
                angle: .front,
                assetIdentifier: "array_front",
                notes: "Array test front"
            ),
            ProgressPhoto(
                date: baseDate.addingTimeInterval(3600),
                angle: .side,
                assetIdentifier: "array_side",
                manualWeight: 170.0
            ),
            ProgressPhoto(
                date: baseDate.addingTimeInterval(7200),
                angle: .back,
                assetIdentifier: "array_back",
                weightSampleUUID: UUID()
            )
        ]
        
        // Encode array to JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let encodedData = try encoder.encode(originalPhotos)
        
        // Decode array from JSON
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedPhotos = try decoder.decode([ProgressPhoto].self, from: encodedData)
        
        // Verify array count
        #expect(decodedPhotos.count == originalPhotos.count)
        
        // Verify each photo in array
        for (original, decoded) in zip(originalPhotos, decodedPhotos) {
            #expect(decoded.id == original.id)
            #expect(decoded.angle == original.angle)
            #expect(decoded.assetIdentifier == original.assetIdentifier)
            #expect(decoded.notes == original.notes)
            #expect(decoded.manualWeight == original.manualWeight)
            #expect(decoded.weightSampleUUID == original.weightSampleUUID)
        }
        
        print("✅ [ProgressPhotoTests.testProgressPhotoJSONArrayEncodingDecoding] Test completed")
    }
    
    // MARK: - Error Handling Tests
    
    @Test("ProgressPhoto JSON decoding handles invalid angle")
    func testProgressPhotoJSONDecodingInvalidAngle() async throws {
        print("🔄 [ProgressPhotoTests.testProgressPhotoJSONDecodingInvalidAngle] Starting test")
        
        setUp()
        defer { tearDown() }
        
        let invalidAngleJSON = """
        {
            "id": "\(UUID().uuidString)",
            "date": "2025-01-15T12:00:00Z",
            "angle": "invalid_angle",
            "assetIdentifier": "test_asset",
            "notes": "",
            "createdAt": "2025-01-15T11:30:00Z"
        }
        """
        
        let jsonData = invalidAngleJSON.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        // Should throw DecodingError due to invalid angle
        #expect(throws: DecodingError.self) {
            try decoder.decode(ProgressPhoto.self, from: jsonData)
        }
        
        print("✅ [ProgressPhotoTests.testProgressPhotoJSONDecodingInvalidAngle] Test completed")
    }
    
    @Test("ProgressPhoto JSON decoding handles missing required fields")
    func testProgressPhotoJSONDecodingMissingFields() async throws {
        print("🔄 [ProgressPhotoTests.testProgressPhotoJSONDecodingMissingFields] Starting test")
        
        setUp()
        defer { tearDown() }
        
        // Missing assetIdentifier field
        let missingAssetJSON = """
        {
            "id": "\(UUID().uuidString)",
            "date": "2025-01-15T12:00:00Z",
            "angle": "front",
            "notes": "",
            "createdAt": "2025-01-15T11:30:00Z"
        }
        """
        
        let jsonData = missingAssetJSON.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        // Should throw DecodingError due to missing required field
        #expect(throws: DecodingError.self) {
            try decoder.decode(ProgressPhoto.self, from: jsonData)
        }
        
        print("✅ [ProgressPhotoTests.testProgressPhotoJSONDecodingMissingFields] Test completed")
    }
    
    // MARK: - Protocol Conformance Tests
    
    @Test("ProgressPhoto conforms to Identified protocol")
    func testProgressPhotoIdentifiedProtocol() async throws {
        print("🔄 [ProgressPhotoTests.testProgressPhotoIdentifiedProtocol] Starting test")
        
        setUp()
        defer { tearDown() }
        
        let progressPhoto = ProgressPhoto(
            date: Date(),
            angle: .front,
            assetIdentifier: "protocol_test"
        )
        
        // Should conform to Identified (has id property)
        let identified: any Identified = progressPhoto
        #expect(identified.id == progressPhoto.id)
        
        // Should be hashable and equatable (from Identified)
        let photo1 = ProgressPhoto(
            date: Date(),
            angle: .front,
            assetIdentifier: "test1"
        )
        let photo2 = ProgressPhoto(
            date: Date(),
            angle: .side,
            assetIdentifier: "test2"
        )
        
        // Different photos should have different hash values
        #expect(photo1.hashValue != photo2.hashValue)
        #expect(photo1 != photo2)
        
        // Same photo should equal itself
        #expect(photo1 == photo1)
        
        print("✅ [ProgressPhotoTests.testProgressPhotoIdentifiedProtocol] Test completed")
    }
    
    @Test("ProgressPhoto conforms to Timestamped protocol")
    func testProgressPhotoTimestampedProtocol() async throws {
        print("🔄 [ProgressPhotoTests.testProgressPhotoTimestampedProtocol] Starting test")
        
        setUp()
        defer { tearDown() }
        
        let testCreatedAt = Date()
        let progressPhoto = ProgressPhoto(
            date: Date(),
            angle: .back,
            assetIdentifier: "timestamp_test",
            createdAt: testCreatedAt
        )
        
        // Should conform to Timestamped (has createdAt property)
        let timestamped: any Timestamped = progressPhoto
        #expect(timestamped.createdAt == testCreatedAt)
        
        print("✅ [ProgressPhotoTests.testProgressPhotoTimestampedProtocol] Test completed")
    }
}