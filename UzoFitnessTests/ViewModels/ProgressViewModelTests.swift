import XCTest
import SwiftData
import UIKit
@testable import UzoFitness

@MainActor
final class ProgressViewModelTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var viewModel: ProgressViewModel!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory model container for testing
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: 
            ProgressPhoto.self,
            PerformedExercise.self,
            Exercise.self,
            WorkoutSession.self,
            WorkoutPlan.self,
            WorkoutTemplate.self,
            SessionExercise.self,
            CompletedSet.self,
            DayTemplate.self,
            ExerciseTemplate.self,
            configurations: config
        )
        
        modelContext = modelContainer.mainContext
        
        // Create real services for testing
        let photoService = PhotoService(
            dataPersistenceService: DefaultDataPersistenceService(modelContext: modelContext)
        )
        let healthKitManager = HealthKitManager()
        
        viewModel = ProgressViewModel(
            modelContext: modelContext,
            photoService: photoService,
            healthKitManager: healthKitManager
        )
        
        // Wait for initial data loading to complete
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        print("✅ [ProgressViewModelTests.setUp] Test environment initialized")
    }
    
    override func tearDown() async throws {
        viewModel = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
        
        print("✅ [ProgressViewModelTests.tearDown] Test environment cleaned up")
    }
    
    // MARK: - Computed Properties Tests
    
    func testGetPhotosForAngle_WithEmptyState_ReturnsEmptyArray() async throws {
        // When
        let frontPhotos = viewModel.getPhotosForAngle(.front)
        let sidePhotos = viewModel.getPhotosForAngle(.side)
        let backPhotos = viewModel.getPhotosForAngle(.back)
        
        // Then
        XCTAssertEqual(frontPhotos.count, 0)
        XCTAssertEqual(sidePhotos.count, 0)
        XCTAssertEqual(backPhotos.count, 0)
        
        print("✅ [ProgressViewModelTests.testGetPhotosForAngle_WithEmptyState_ReturnsEmptyArray] Passed")
    }
    
    func testGetExerciseOptions_WithEmptyState_ReturnsEmptyArray() async throws {
        // When
        let options = viewModel.getExerciseOptions()
        
        // Then
        XCTAssertEqual(options.count, 0)
        
        print("✅ [ProgressViewModelTests.testGetExerciseOptions_WithEmptyState_ReturnsEmptyArray] Passed")
    }
    
    // MARK: - Helper Struct Tests
    
    func testExerciseTrend_CalculatesMetricsCorrectly() async throws {
        // Given
        let exercise = Exercise(name: "Test Exercise", category: .strength)
        let performedExercises = [
            PerformedExercise(performedAt: Date(), reps: 10, weight: 100, exercise: exercise),
            PerformedExercise(performedAt: Date(), reps: 8, weight: 120, exercise: exercise),
            PerformedExercise(performedAt: Date(), reps: 12, weight: 90, exercise: exercise)
        ]
        
        // When
        let trend = ExerciseTrend(
            exerciseID: exercise.id,
            exerciseName: exercise.name,
            performedExercises: performedExercises,
            weekStartDate: Date()
        )
        
        // Then
        XCTAssertEqual(trend.maxWeight, 120.0)
        let expectedVolume = (100.0 * 10.0) + (120.0 * 8.0) + (90.0 * 12.0) // 1000 + 960 + 1080 = 3040
        XCTAssertEqual(trend.totalVolume, expectedVolume)
        XCTAssertEqual(trend.totalSessions, 3)
        
        print("✅ [ProgressViewModelTests.testExerciseTrend_CalculatesMetricsCorrectly] Passed")
    }
    
    func testBodyMetrics_FormatsValuesCorrectly() async throws {
        // Given
        let photoID = UUID()
        let weight = 175.5
        let bodyFat = 0.15 // 15%
        
        // When
        let metrics = BodyMetrics(photoID: photoID, weight: weight, bodyFat: bodyFat, date: Date())
        
        // Then
        XCTAssertEqual(metrics.photoID, photoID)
        XCTAssertEqual(metrics.weight, weight)
        XCTAssertEqual(metrics.bodyFat, bodyFat)
        XCTAssertEqual(metrics.formattedWeight, "175.5 lbs")
        XCTAssertEqual(metrics.formattedBodyFat, "15.0%")
        
        print("✅ [ProgressViewModelTests.testBodyMetrics_FormatsValuesCorrectly] Passed")
    }
    
    func testBodyMetrics_HandlesNilValues() async throws {
        // Given
        let photoID = UUID()
        
        // When
        let metrics = BodyMetrics(photoID: photoID, weight: nil, bodyFat: nil, date: Date())
        
        // Then
        XCTAssertNil(metrics.weight)
        XCTAssertNil(metrics.bodyFat)
        XCTAssertEqual(metrics.formattedWeight, "N/A")
        XCTAssertEqual(metrics.formattedBodyFat, "N/A")
        
        print("✅ [ProgressViewModelTests.testBodyMetrics_HandlesNilValues] Passed")
    }
    
    // MARK: - Enum Tests
    
    func testMetricType_HasCorrectDisplayNames() async throws {
        // Then
        XCTAssertEqual(MetricType.maxWeight.displayName, "Max Weight")
        XCTAssertEqual(MetricType.totalVolume.displayName, "Total Volume")
        XCTAssertEqual(MetricType.totalSessions.displayName, "Total Sets")
        XCTAssertEqual(MetricType.totalReps.displayName, "Total Reps")
        
        print("✅ [ProgressViewModelTests.testMetricType_HasCorrectDisplayNames] Passed")
    }
    
    func testMetricType_HasCorrectUnits() async throws {
        // Then
        XCTAssertEqual(MetricType.maxWeight.unit, "lbs")
        XCTAssertEqual(MetricType.totalVolume.unit, "lbs")
        XCTAssertEqual(MetricType.totalSessions.unit, "sets")
        XCTAssertEqual(MetricType.totalReps.unit, "reps")
        
        print("✅ [ProgressViewModelTests.testMetricType_HasCorrectUnits] Passed")
    }
    
    func testProgressError_HasCorrectDescriptions() async throws {
        // Then
        XCTAssertEqual(ProgressError.photoNotFound.errorDescription, "The requested photo could not be found.")
        XCTAssertEqual(ProgressError.healthKitUnavailable.errorDescription, "HealthKit is not available on this device.")
        XCTAssertEqual(ProgressError.dataLoadFailed.errorDescription, "Failed to load progress data.")
        XCTAssertEqual(ProgressError.invalidImageData.errorDescription, "The selected image data is invalid.")
        XCTAssertEqual(ProgressError.photoServiceError("Test").errorDescription, "Photo service error: Test")
        XCTAssertEqual(ProgressError.custom("Custom message").errorDescription, "Custom message")
        
        print("✅ [ProgressViewModelTests.testProgressError_HasCorrectDescriptions] Passed")
    }

    func testAddPhoto_SavesToCacheAndUpdatesViewModel() async throws {
        // Given
        let image = UIImage(systemName: "person.fill")!
        let angle = PhotoAngle.front
        
        // When
        await viewModel.handleIntent(.addPhoto(angle, image))
        
        // A short sleep to allow async operations inside the view model to complete.
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Then
        // 1. Check if the ViewModel's state is updated
        let photos = viewModel.getPhotosForAngle(angle)
        XCTAssertEqual(photos.count, 1, "ViewModel should have one photo for the specified angle.")
        
        guard let savedPhoto = photos.first else {
            XCTFail("Could not retrieve the saved photo from the ViewModel.")
            return
        }
        
        // 2. Verify the assetIdentifier is a valid file URL
        guard let url = URL(string: savedPhoto.assetIdentifier) else {
            XCTFail("The assetIdentifier is not a valid URL string: \(savedPhoto.assetIdentifier)")
            return
        }
        XCTAssertTrue(url.isFileURL, "The URL created from assetIdentifier should be a file URL.")
        
        // 3. Verify the file exists in the cache
        let fileManager = FileManager.default
        XCTAssertTrue(fileManager.fileExists(atPath: url.path), "The image file should exist at the path from the assetIdentifier.")
        
        // 4. Clean up the created file
        try? fileManager.removeItem(at: url)
        
        print("✅ [ProgressViewModelTests.testAddPhoto_SavesToCacheAndUpdatesViewModel] Passed")
    }
}

 
