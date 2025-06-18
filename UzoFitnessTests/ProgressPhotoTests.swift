import XCTest
import SwiftData
@testable import UzoFitness  // replace with your module name if different

final class ProgressPhotoTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUpWithError() throws {
        // Create an in-memory model container for ProgressPhoto.
        // If ProgressPhoto depends on other models, include them here as well:
        // try ModelContainer(for: [ProgressPhoto.self, OtherModel.self])
        container = try ModelContainer(for: ProgressPhoto.self)
        context = ModelContext(container)
    }

    override func tearDown() {
        context = nil
        container = nil
    }

    func testInitializerSetsAllProperties() throws {
        // Given
        let testDate = Date()
        // Replace PhotoAngle.front with an actual case from your PhotoAngle enum
        let testAngle = PhotoAngle.front
        let testAssetId = "asset-123"
        let testWeightSampleUUID = UUID()
        let testNotes = "These are test notes"
        // Use a fixed createdAt for predictable testing
        let testCreatedAt = Date(timeIntervalSince1970: 1_600_000_000)

        // When
        let testId = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
        let photo = ProgressPhoto(
            id: testId,
            date: testDate,
            angle: testAngle,
            assetIdentifier: testAssetId,
            weightSampleUUID: testWeightSampleUUID,
            notes: testNotes,
            createdAt: testCreatedAt
        )

        // Then
        XCTAssertEqual(photo.id, testId, "Initializer should set id correctly")
        XCTAssertEqual(photo.date, testDate, "Initializer should set date correctly")
        XCTAssertEqual(photo.angle, testAngle, "Initializer should set angle correctly")
        XCTAssertEqual(photo.assetIdentifier, testAssetId, "Initializer should set assetIdentifier correctly")
        XCTAssertEqual(photo.weightSampleUUID, testWeightSampleUUID, "Initializer should set weightSampleUUID correctly")
        XCTAssertEqual(photo.notes, testNotes, "Initializer should set notes correctly")
        XCTAssertEqual(photo.createdAt, testCreatedAt, "Initializer should set createdAt correctly")
    }

    func testDefaultInitializerCreatedAtIsNow() throws {
        // Given
        let beforeInit = Date()
        let testDate = Date()
        let testAngle = PhotoAngle.front
        let testAssetId = "asset-abc"

        // When
        let photo = ProgressPhoto(
            date: testDate,
            angle: testAngle,
            assetIdentifier: testAssetId
            // weightSampleUUID and notes and createdAt use defaults
        )
        let afterInit = Date()

        // Then
        // createdAt should be between beforeInit and afterInit (inclusive-ish)
        XCTAssert(photo.createdAt >= beforeInit, "createdAt should be >= the time just before init")
        XCTAssert(photo.createdAt <= afterInit, "createdAt should be <= the time just after init")
    }

    func testInsertAndFetchProgressPhoto() throws {
        // Given
        let testDate = Date()
        let testAngle = PhotoAngle.front
        let testAssetId = "asset-xyz"
        let photo = ProgressPhoto(date: testDate, angle: testAngle, assetIdentifier: testAssetId)

        // When
        context.insert(photo)
        // For SwiftData, insert is immediate in-memory. To fetch, use FetchDescriptor.
        let fetchDescriptor = FetchDescriptor<ProgressPhoto>()
        let results = try context.fetch(fetchDescriptor)

        // Then
        XCTAssertEqual(results.count, 1, "There should be exactly one ProgressPhoto in the context")
        let fetched = results[0]
        XCTAssertEqual(fetched.id, photo.id)
        XCTAssertEqual(fetched.date, testDate)
        XCTAssertEqual(fetched.angle, testAngle)
        XCTAssertEqual(fetched.assetIdentifier, testAssetId)
    }

    func testMultipleInsertsDifferentIDs() throws {
        // Given
        let photo1 = ProgressPhoto(date: Date(), angle: .front, assetIdentifier: "asset1")
        let photo2 = ProgressPhoto(date: Date().addingTimeInterval(60), angle: .side, assetIdentifier: "asset2")

        // When
        context.insert(photo1)
        context.insert(photo2)
        let results = try context.fetch(FetchDescriptor<ProgressPhoto>())

        // Then
        XCTAssertEqual(results.count, 2, "Should be able to insert two ProgressPhoto instances with different IDs")
    }
}
