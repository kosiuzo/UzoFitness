import XCTest
import SwiftData
import UIKit
import HealthKit
import UzoFitnessCore
@testable import UzoFitness

@MainActor
class ProgressViewModelTests: XCTestCase {
    
    // MARK: - Test Properties
    private var persistenceController: InMemoryPersistenceController!
    private var viewModel: ProgressViewModel!
    private var mockPhotoService: PhotoService!
    private var mockHealthKitManager: HealthKitManager!
    
    // MARK: - Setup and Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory persistence controller
        persistenceController = InMemoryPersistenceController()
        
        // Create mock services
        mockPhotoService = PhotoService(
            fileSystemService: MockFileSystemService(),
            imagePickerService: MockImagePickerService(),
            dataPersistenceService: DefaultDataPersistenceService(modelContext: persistenceController.context)
        )
        
        mockHealthKitManager = HealthKitManager(
            healthStore: MockHealthStore(),
            calendar: CalendarWrapper(Calendar.current),
            typeFactory: HealthKitTypeFactory(),
            queryExecutor: MockQueryExecutor()
        )
        
        // Create view model with test dependencies
        viewModel = ProgressViewModel(
            modelContext: persistenceController.context,
            photoService: mockPhotoService,
            healthKitManager: mockHealthKitManager
        )
        
        // Wait for initial setup
        await TestHelpers.wait(seconds: 0.1)
    }
    
    override func tearDown() async throws {
        // Clean up test data
        persistenceController.cleanupTestData()
        viewModel = nil
        mockPhotoService = nil
        mockHealthKitManager = nil
        persistenceController = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    
    func testInitialization_ComputedPropertiesWithEmptyData() {
        // Given: A newly initialized ProgressViewModel with no data
        // (viewModel created in setUp)
        
        // Then: Computed properties should handle empty state gracefully
        XCTAssertEqual(viewModel.trendChartData.count, 0, "Should return empty chart data with no exercise trends")
        XCTAssertFalse(viewModel.canCompare, "Should not be able to compare with no photos selected")
        XCTAssertNil(viewModel.selectedExerciseName, "Should return nil exercise name with no selection")
        XCTAssertEqual(viewModel.totalPhotos, 0, "Should return zero total photos with empty data")
        XCTAssertEqual(viewModel.photosThisMonth, 0, "Should return zero photos this month with empty data")
        XCTAssertNil(viewModel.latestPhoto, "Should return nil latest photo with empty data")
        
        let (firstPhoto, secondPhoto) = viewModel.comparisonPhotos
        XCTAssertNil(firstPhoto, "First comparison photo should be nil")
        XCTAssertNil(secondPhoto, "Second comparison photo should be nil")
    }
    
    
    
    func testInitialization_DefaultLoadingStates() {
        // Given: A newly initialized ProgressViewModel
        // (viewModel created in setUp)
        
        // Then: Loading states should be properly initialized
        XCTAssertFalse(viewModel.isLoadingStats, "Stats loading should be false initially")
        XCTAssertFalse(viewModel.isLoadingPhotos, "Photos loading should be false initially")
        XCTAssertFalse(viewModel.showImagePicker, "Image picker should be hidden initially")
        XCTAssertEqual(viewModel.selectedPhotoAngle, .front, "Default photo angle should be front")
    }
    
    // MARK: - Empty State Tests
    
    func testEmptyState_HandlesNoExerciseData() {
        // Given: A ProgressViewModel with no exercise data
        // (viewModel created in setUp with empty data)
        
        // Then: Should handle empty exercise state gracefully
        XCTAssertEqual(viewModel.exerciseTrends.count, 0, "Exercise trends should be empty")
        XCTAssertEqual(viewModel.getExerciseOptions().count, 0, "Exercise options should be empty")
        XCTAssertNil(viewModel.getLatestTrendForExercise(UUID()), "Should return nil for any exercise ID")
        XCTAssertEqual(viewModel.trendChartData.count, 0, "Chart data should be empty")
        XCTAssertNil(viewModel.selectedExerciseName, "Selected exercise name should be nil")
    }
    
    func testEmptyState_HandlesNoPhotoData() {
        // Given: A ProgressViewModel with no photo data
        // (viewModel created in setUp with empty data)
        
        // Then: Should handle empty photo state gracefully
        XCTAssertEqual(viewModel.totalPhotos, 0, "Total photos should be zero")
        XCTAssertEqual(viewModel.photosThisMonth, 0, "Photos this month should be zero")
        XCTAssertNil(viewModel.latestPhoto, "Latest photo should be nil")
        
        // Test photo retrieval for all angles
        for angle in PhotoAngle.allCases {
            XCTAssertEqual(viewModel.getPhotosForAngle(angle).count, 0, "Should return empty array for angle \(angle)")
        }
        
        XCTAssertNil(viewModel.getMetricsForPhoto(UUID()), "Should return nil metrics for any photo ID")
    }
    
    func testEmptyState_ComparisonFunctionality() {
        // Given: A ProgressViewModel with no photo data
        // (viewModel created in setUp with empty data)
        
        // Then: Comparison functionality should handle empty state
        XCTAssertFalse(viewModel.canCompare, "Should not be able to compare with no photos")
        
        let (firstPhoto, secondPhoto) = viewModel.comparisonPhotos
        XCTAssertNil(firstPhoto, "First comparison photo should be nil")
        XCTAssertNil(secondPhoto, "Second comparison photo should be nil")
        
        // Test that comparison selection state is properly initialized
        XCTAssertNil(viewModel.compareSelection.0, "First comparison selection should be nil")
        XCTAssertNil(viewModel.compareSelection.1, "Second comparison selection should be nil")
    }
    
    func testEmptyState_LoadingStatesInitiallyFalse() {
        // Given: A ProgressViewModel with no data
        // (viewModel created in setUp with empty data)
        
        // Then: Loading states should be false initially
        XCTAssertFalse(viewModel.isLoadingStats, "Stats loading should be false initially")
        XCTAssertFalse(viewModel.isLoadingPhotos, "Photos loading should be false initially")
        XCTAssertEqual(viewModel.exerciseTrends.count, 0, "Exercise trends should be empty")
        XCTAssertEqual(viewModel.totalPhotos, 0, "Total photos should be zero")
    }
    
    func testEmptyState_MetricCalculations() {
        // Given: A ProgressViewModel with no data
        // (viewModel created in setUp with empty data)
        
        // When: Accessing metric-related computed properties
        let chartData = viewModel.trendChartData
        let exerciseOptions = viewModel.getExerciseOptions()
        
        // Then: Should return empty collections without errors
        XCTAssertEqual(chartData.count, 0, "Chart data should be empty")
        XCTAssertEqual(exerciseOptions.count, 0, "Exercise options should be empty")
        
        // Test metric type property directly
        XCTAssertEqual(viewModel.selectedMetricType, .maxWeight, "Default metric type should be maxWeight")
        XCTAssertEqual(viewModel.trendChartData.count, 0, "Chart data should be empty for default metric type")
    }
    
    func testEmptyState_ErrorHandling() {
        // Given: A ProgressViewModel with no data
        // (viewModel created in setUp with empty data)
        
        // When: Accessing properties with empty state
        let selectedExerciseName = viewModel.selectedExerciseName
        let totalPhotos = viewModel.totalPhotos
        let latestPhoto = viewModel.latestPhoto
        
        // Then: Should handle gracefully without crashing
        XCTAssertNil(selectedExerciseName, "Selected exercise name should be nil with no data")
        XCTAssertEqual(totalPhotos, 0, "Total photos should be zero with no data")
        XCTAssertNil(latestPhoto, "Latest photo should be nil with no data")
    }
    
    // MARK: - Exercise Options Tests
    
    func testExerciseOptions_EmptyData_ReturnsEmptyArray() {
        // Given: A ProgressViewModel with no exercise data
        // (viewModel created in setUp with empty data)
        
        // When: Getting exercise options
        let options = viewModel.getExerciseOptions()
        
        // Then: Should return empty array
        XCTAssertEqual(options.count, 0, "Exercise options should be empty with no data")
    }
    
    func testExerciseOptions_WithEmptyTrends_ReturnsEmpty() {
        // Given: A ProgressViewModel with no exercise trend data
        // (viewModel created in setUp with empty data)
        
        // When: Getting exercise options
        let options = viewModel.getExerciseOptions()
        
        // Then: Should return empty array
        XCTAssertEqual(options.count, 0, "Exercise options should be empty with no trend data")
    }
    
    func testExerciseOptions_WithManualTrendData_ReturnsSorted() {
        // Given: A ProgressViewModel with manually set exercise trends
        let exerciseID1 = UUID()
        let exerciseID2 = UUID()
        let exerciseID3 = UUID()
        
        let trend1 = ExerciseTrend(exerciseID: exerciseID1, exerciseName: "Zebra Exercise", performedExercises: [], weekStartDate: Date())
        let trend2 = ExerciseTrend(exerciseID: exerciseID2, exerciseName: "Alpha Exercise", performedExercises: [], weekStartDate: Date())
        let trend3 = ExerciseTrend(exerciseID: exerciseID3, exerciseName: "Beta Exercise", performedExercises: [], weekStartDate: Date())
        
        viewModel.exerciseTrends = [trend1, trend2, trend3]
        
        // When: Getting exercise options
        let options = viewModel.getExerciseOptions()
        
        // Then: Should return sorted exercise options
        XCTAssertEqual(options.count, 3, "Should have three exercise options")
        
        let sortedNames = options.map { $0.1 }
        XCTAssertEqual(sortedNames[0], "Alpha Exercise", "First exercise should be alphabetically first")
        XCTAssertEqual(sortedNames[1], "Beta Exercise", "Second exercise should be Beta")
        XCTAssertEqual(sortedNames[2], "Zebra Exercise", "Last exercise should be alphabetically last")
    }
    
    // MARK: - Metrics Tests
    
    func testMetrics_DefaultMetricType() {
        // Given: A newly initialized ProgressViewModel
        // (viewModel created in setUp)
        
        // Then: Default metric type should be maxWeight
        XCTAssertEqual(viewModel.selectedMetricType, .maxWeight, "Default metric type should be maxWeight")
    }
    
    func testMetrics_TrendChartDataWithNoSelection() {
        // Given: A ProgressViewModel with no selected exercise
        viewModel.selectedExerciseID = nil
        
        // When: Getting trend chart data
        let chartData = viewModel.trendChartData
        
        // Then: Should return empty array
        XCTAssertEqual(chartData.count, 0, "Chart data should be empty with no exercise selected")
    }
    
    func testMetrics_TrendChartDataWithSelectedExercise() {
        // Given: A ProgressViewModel with exercise trends and selected exercise
        let exerciseID = UUID()
        let baseDate = Date()
        
        // Create mock performed exercises for trend calculations
        let exercise = TestHelpers.createTestExercise(name: "Bench Press")
        let performedExercise1 = TestHelpers.createTestPerformedExercise(
            exercise: exercise,
            reps: 10,
            weight: 135,
            performedAt: baseDate
        )
        let performedExercise2 = TestHelpers.createTestPerformedExercise(
            exercise: exercise,
            reps: 8,
            weight: 145,
            performedAt: baseDate.addingTimeInterval(86400)
        )
        
        let trend1 = ExerciseTrend(
            exerciseID: exerciseID,
            exerciseName: "Bench Press",
            performedExercises: [performedExercise1],
            weekStartDate: baseDate
        )
        let trend2 = ExerciseTrend(
            exerciseID: exerciseID,
            exerciseName: "Bench Press",
            performedExercises: [performedExercise2],
            weekStartDate: baseDate.addingTimeInterval(604800) // 1 week later
        )
        
        viewModel.exerciseTrends = [trend1, trend2]
        viewModel.selectedExerciseID = exerciseID
        
        // When: Getting trend chart data for maxWeight metric
        viewModel.selectedMetricType = .maxWeight
        let maxWeightData = viewModel.trendChartData
        
        // Then: Should return chart data with max weights
        XCTAssertEqual(maxWeightData.count, 2, "Should have two data points")
        XCTAssertEqual(maxWeightData[0].value, 135, "First data point should have max weight of 135")
        XCTAssertEqual(maxWeightData[1].value, 145, "Second data point should have max weight of 145")
    }
    
    
    func testMetrics_CurrentWeightInitiallyNil() {
        // Given: A newly initialized ProgressViewModel
        // (viewModel created in setUp)
        
        // Then: Current weight should be nil initially
        XCTAssertNil(viewModel.currentWeight, "Current weight should be nil initially")
    }
    
    func testMetrics_PhotoMetricsInitiallyEmpty() {
        // Given: A newly initialized ProgressViewModel
        // (viewModel created in setUp)
        
        // Then: Photo metrics should be empty initially
        XCTAssertEqual(viewModel.photoMetrics.count, 0, "Photo metrics should be empty initially")
    }
    
    func testMetrics_GetMetricsForPhotoWithNoData() {
        // Given: A ProgressViewModel with no photo metrics
        let photoID = UUID()
        
        // When: Getting metrics for a photo
        let metrics = viewModel.getMetricsForPhoto(photoID)
        
        // Then: Should return nil
        XCTAssertNil(metrics, "Should return nil for photo with no metrics")
    }
    
    func testMetrics_GetMetricsForPhotoWithData() {
        // Given: A ProgressViewModel with photo metrics
        let photoID = UUID()
        let testMetrics = BodyMetrics(
            photoID: photoID,
            weight: 180.0,
            bodyFat: 0.15,
            date: Date()
        )
        
        viewModel.photoMetrics[photoID] = testMetrics
        
        // When: Getting metrics for the photo
        let metrics = viewModel.getMetricsForPhoto(photoID)
        
        // Then: Should return the correct metrics
        XCTAssertNotNil(metrics, "Should return metrics for photo")
        XCTAssertEqual(metrics?.photoID, photoID, "Photo ID should match")
        XCTAssertEqual(metrics?.weight, 180.0, "Weight should match")
        XCTAssertEqual(metrics?.bodyFat, 0.15, "Body fat should match")
    }
    
    func testMetrics_GetLatestTrendForExerciseWithNoData() {
        // Given: A ProgressViewModel with no exercise trends
        let exerciseID = UUID()
        
        // When: Getting latest trend for exercise
        let trend = viewModel.getLatestTrendForExercise(exerciseID)
        
        // Then: Should return nil
        XCTAssertNil(trend, "Should return nil for exercise with no trends")
    }
    
    func testMetrics_GetLatestTrendForExerciseWithData() {
        // Given: A ProgressViewModel with multiple trends for an exercise
        let exerciseID = UUID()
        let baseDate = Date()
        
        let trend1 = ExerciseTrend(
            exerciseID: exerciseID,
            exerciseName: "Bench Press",
            performedExercises: [],
            weekStartDate: baseDate
        )
        let trend2 = ExerciseTrend(
            exerciseID: exerciseID,
            exerciseName: "Bench Press",
            performedExercises: [],
            weekStartDate: baseDate.addingTimeInterval(604800) // 1 week later
        )
        let trend3 = ExerciseTrend(
            exerciseID: exerciseID,
            exerciseName: "Bench Press",
            performedExercises: [],
            weekStartDate: baseDate.addingTimeInterval(-604800) // 1 week earlier
        )
        
        viewModel.exerciseTrends = [trend1, trend2, trend3]
        
        // When: Getting latest trend for exercise
        let latestTrend = viewModel.getLatestTrendForExercise(exerciseID)
        
        // Then: Should return the most recent trend
        XCTAssertNotNil(latestTrend, "Should return a trend")
        XCTAssertEqual(latestTrend?.weekStartDate, trend2.weekStartDate, "Should return the latest trend by date")
    }
    
    func testMetrics_TrendChartDataSortedByDate() {
        // Given: A ProgressViewModel with trends in random order
        let exerciseID = UUID()
        let baseDate = Date()
        
        let trend2 = ExerciseTrend(
            exerciseID: exerciseID,
            exerciseName: "Bench Press",
            performedExercises: [],
            weekStartDate: baseDate.addingTimeInterval(604800) // 1 week later
        )
        let trend1 = ExerciseTrend(
            exerciseID: exerciseID,
            exerciseName: "Bench Press",
            performedExercises: [],
            weekStartDate: baseDate
        )
        let trend3 = ExerciseTrend(
            exerciseID: exerciseID,
            exerciseName: "Bench Press",
            performedExercises: [],
            weekStartDate: baseDate.addingTimeInterval(1209600) // 2 weeks later
        )
        
        // Add trends in random order
        viewModel.exerciseTrends = [trend2, trend1, trend3]
        viewModel.selectedExerciseID = exerciseID
        
        // When: Getting trend chart data
        let chartData = viewModel.trendChartData
        
        // Then: Should be sorted by date (earliest first)
        XCTAssertEqual(chartData.count, 3, "Should have three data points")
        XCTAssertTrue(chartData[0].date <= chartData[1].date, "Data should be sorted by date")
        XCTAssertTrue(chartData[1].date <= chartData[2].date, "Data should be sorted by date")
        XCTAssertEqual(chartData[0].date, baseDate, "First data point should be earliest")
        XCTAssertEqual(chartData[2].date, baseDate.addingTimeInterval(1209600), "Last data point should be latest")
    }
    
    func testMetrics_TotalPhotosCalculation() {
        // Given: A ProgressViewModel with photos in different angles
        let photo1 = TestHelpers.createTestProgressPhoto(angle: .front)
        let photo2 = TestHelpers.createTestProgressPhoto(angle: .side)
        let photo3 = TestHelpers.createTestProgressPhoto(angle: .back)
        let photo4 = TestHelpers.createTestProgressPhoto(angle: .front)
        
        viewModel.photosByAngle = [
            .front: [photo1, photo4],
            .side: [photo2],
            .back: [photo3]
        ]
        
        // When: Getting total photos
        let total = viewModel.totalPhotos
        
        // Then: Should count all photos across all angles
        XCTAssertEqual(total, 4, "Should count all photos across all angles")
    }
    
    func testMetrics_PhotosThisMonthCalculation() {
        // Given: A ProgressViewModel with photos from different months
        let now = Date()
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        
        let recentPhoto1 = TestHelpers.createTestProgressPhoto(date: now, angle: .front)
        let recentPhoto2 = TestHelpers.createTestProgressPhoto(date: startOfMonth, angle: .side)
        let oldPhoto = TestHelpers.createTestProgressPhoto(date: lastMonth, angle: .back)
        
        viewModel.photosByAngle = [
            .front: [recentPhoto1],
            .side: [recentPhoto2],
            .back: [oldPhoto]
        ]
        
        // When: Getting photos this month
        let thisMonth = viewModel.photosThisMonth
        
        // Then: Should only count photos from this month
        XCTAssertEqual(thisMonth, 2, "Should only count photos from this month")
    }
    
    func testMetrics_LatestPhotoCalculation() {
        // Given: A ProgressViewModel with photos from different dates
        let baseDate = Date()
        let photo1 = TestHelpers.createTestProgressPhoto(date: baseDate, angle: .front)
        let photo2 = TestHelpers.createTestProgressPhoto(date: baseDate.addingTimeInterval(86400), angle: .side)
        let photo3 = TestHelpers.createTestProgressPhoto(date: baseDate.addingTimeInterval(-86400), angle: .back)
        
        viewModel.photosByAngle = [
            .front: [photo1],
            .side: [photo2],
            .back: [photo3]
        ]
        
        // When: Getting latest photo
        let latest = viewModel.latestPhoto
        
        // Then: Should return the most recent photo
        XCTAssertNotNil(latest, "Should return a photo")
        XCTAssertEqual(latest?.id, photo2.id, "Should return the most recent photo")
        XCTAssertEqual(latest?.angle, .side, "Latest photo should be the side angle photo")
    }
    
    // MARK: - Photo Management Tests
    
    func testPhotoManagement_GetPhotosForAngleEmptyState() {
        // Given: A ProgressViewModel with no photos
        // (viewModel created in setUp with empty data)
        
        // When: Getting photos for each angle
        for angle in PhotoAngle.allCases {
            let photos = viewModel.getPhotosForAngle(angle)
            
            // Then: Should return empty array for all angles
            XCTAssertEqual(photos.count, 0, "Should return empty array for angle \(angle)")
        }
    }
    
    func testPhotoManagement_GetPhotosForAngleWithData() {
        // Given: A ProgressViewModel with photos for different angles
        let frontPhoto1 = TestHelpers.createTestProgressPhoto(angle: .front)
        let frontPhoto2 = TestHelpers.createTestProgressPhoto(angle: .front)
        let sidePhoto = TestHelpers.createTestProgressPhoto(angle: .side)
        let backPhoto = TestHelpers.createTestProgressPhoto(angle: .back)
        
        viewModel.photosByAngle = [
            .front: [frontPhoto1, frontPhoto2],
            .side: [sidePhoto],
            .back: [backPhoto]
        ]
        
        // When: Getting photos for each angle
        let frontPhotos = viewModel.getPhotosForAngle(.front)
        let sidePhotos = viewModel.getPhotosForAngle(.side)
        let backPhotos = viewModel.getPhotosForAngle(.back)
        
        // Then: Should return correct photos for each angle
        XCTAssertEqual(frontPhotos.count, 2, "Should return 2 front photos")
        XCTAssertEqual(sidePhotos.count, 1, "Should return 1 side photo")
        XCTAssertEqual(backPhotos.count, 1, "Should return 1 back photo")
        
        XCTAssertTrue(frontPhotos.contains { $0.id == frontPhoto1.id }, "Should contain first front photo")
        XCTAssertTrue(frontPhotos.contains { $0.id == frontPhoto2.id }, "Should contain second front photo")
        XCTAssertEqual(sidePhotos.first?.id, sidePhoto.id, "Should return correct side photo")
        XCTAssertEqual(backPhotos.first?.id, backPhoto.id, "Should return correct back photo")
    }
    
    func testPhotoManagement_ComparisonFunctionalityEmpty() {
        // Given: A ProgressViewModel with no photos
        // (viewModel created in setUp with empty data)
        
        // When: Checking comparison capability
        let canCompare = viewModel.canCompare
        let (firstPhoto, secondPhoto) = viewModel.comparisonPhotos
        
        // Then: Should not be able to compare
        XCTAssertFalse(canCompare, "Should not be able to compare with no photos")
        XCTAssertNil(firstPhoto, "First comparison photo should be nil")
        XCTAssertNil(secondPhoto, "Second comparison photo should be nil")
        XCTAssertNil(viewModel.compareSelection.0, "First selection should be nil")
        XCTAssertNil(viewModel.compareSelection.1, "Second selection should be nil")
    }
    
    func testPhotoManagement_ComparisonFunctionalityWithPhotos() {
        // Given: A ProgressViewModel with photos
        let photo1 = TestHelpers.createTestProgressPhoto(angle: .front)
        let photo2 = TestHelpers.createTestProgressPhoto(angle: .side)
        let photo3 = TestHelpers.createTestProgressPhoto(angle: .back)
        
        viewModel.photosByAngle = [
            .front: [photo1],
            .side: [photo2],
            .back: [photo3]
        ]
        
        // When: Selecting photos for comparison
        viewModel.compareSelection = (photo1.id, photo2.id)
        
        // Then: Should be able to compare
        XCTAssertTrue(viewModel.canCompare, "Should be able to compare with two different photos selected")
        
        let (firstPhoto, secondPhoto) = viewModel.comparisonPhotos
        XCTAssertNotNil(firstPhoto, "First comparison photo should not be nil")
        XCTAssertNotNil(secondPhoto, "Second comparison photo should not be nil")
        XCTAssertEqual(firstPhoto?.id, photo1.id, "First photo should match selection")
        XCTAssertEqual(secondPhoto?.id, photo2.id, "Second photo should match selection")
    }
    
    func testPhotoManagement_ComparisonSamePhoto() {
        // Given: A ProgressViewModel with photos
        let photo1 = TestHelpers.createTestProgressPhoto(angle: .front)
        let photo2 = TestHelpers.createTestProgressPhoto(angle: .side)
        
        viewModel.photosByAngle = [
            .front: [photo1],
            .side: [photo2]
        ]
        
        // When: Selecting the same photo twice
        viewModel.compareSelection = (photo1.id, photo1.id)
        
        // Then: Should not be able to compare
        XCTAssertFalse(viewModel.canCompare, "Should not be able to compare the same photo with itself")
    }
    
    func testPhotoManagement_ComparisonPartialSelection() {
        // Given: A ProgressViewModel with photos
        let photo1 = TestHelpers.createTestProgressPhoto(angle: .front)
        
        viewModel.photosByAngle = [
            .front: [photo1]
        ]
        
        // When: Selecting only one photo
        viewModel.compareSelection = (photo1.id, nil)
        
        // Then: Should not be able to compare
        XCTAssertFalse(viewModel.canCompare, "Should not be able to compare with only one photo selected")
        
        // When: Selecting second photo as nil
        viewModel.compareSelection = (nil, photo1.id)
        
        // Then: Should still not be able to compare
        XCTAssertFalse(viewModel.canCompare, "Should not be able to compare with only second photo selected")
    }
    
    func testPhotoManagement_LoadingStatesInitialization() {
        // Given: A newly initialized ProgressViewModel
        // (viewModel created in setUp)
        
        // Then: Photo loading states should be properly initialized
        XCTAssertFalse(viewModel.isLoadingPhotos, "Photo loading should be false initially")
        XCTAssertFalse(viewModel.showImagePicker, "Image picker should be hidden initially")
        XCTAssertEqual(viewModel.selectedPhotoAngle, .front, "Default photo angle should be front")
    }
    
    
    func testPhotoManagement_PhotoAngleSelection() {
        // Given: A ProgressViewModel with default angle
        // (viewModel created in setUp)
        
        // Then: Default selected angle should be front
        XCTAssertEqual(viewModel.selectedPhotoAngle, .front, "Default selected angle should be front")
        
        // When: Manually changing selected angle (simulating UI interaction)
        viewModel.selectedPhotoAngle = .side
        
        // Then: Selected angle should be updated
        XCTAssertEqual(viewModel.selectedPhotoAngle, .side, "Selected angle should be updated to side")
        
        // When: Changing to back angle
        viewModel.selectedPhotoAngle = .back
        
        // Then: Selected angle should be back
        XCTAssertEqual(viewModel.selectedPhotoAngle, .back, "Selected angle should be updated to back")
    }
    
    func testPhotoManagement_ImagePickerState() {
        // Given: A ProgressViewModel with image picker hidden
        // (viewModel created in setUp)
        
        // Then: Image picker should be hidden initially
        XCTAssertFalse(viewModel.showImagePicker, "Image picker should be hidden initially")
        
        // When: Manually showing image picker (simulating UI interaction)
        viewModel.showImagePicker = true
        
        // Then: Image picker should be shown
        XCTAssertTrue(viewModel.showImagePicker, "Image picker should be shown")
        
        // When: Hiding image picker
        viewModel.showImagePicker = false
        
        // Then: Image picker should be hidden
        XCTAssertFalse(viewModel.showImagePicker, "Image picker should be hidden")
    }
    
    func testPhotoManagement_PhotoMetricsHandling() {
        // Given: A ProgressViewModel with photo metrics
        let photo1 = TestHelpers.createTestProgressPhoto(angle: .front)
        let photo2 = TestHelpers.createTestProgressPhoto(angle: .side)
        
        let metrics1 = BodyMetrics(
            photoID: photo1.id,
            weight: 180.0,
            bodyFat: 0.15,
            date: photo1.date
        )
        let metrics2 = BodyMetrics(
            photoID: photo2.id,
            weight: 175.0,
            bodyFat: 0.12,
            date: photo2.date
        )
        
        viewModel.photosByAngle = [
            .front: [photo1],
            .side: [photo2]
        ]
        viewModel.photoMetrics = [
            photo1.id: metrics1,
            photo2.id: metrics2
        ]
        
        // When: Getting metrics for existing photos
        let retrievedMetrics1 = viewModel.getMetricsForPhoto(photo1.id)
        let retrievedMetrics2 = viewModel.getMetricsForPhoto(photo2.id)
        
        // Then: Should return correct metrics
        XCTAssertNotNil(retrievedMetrics1, "Should return metrics for first photo")
        XCTAssertEqual(retrievedMetrics1?.weight, 180.0, "First photo weight should match")
        XCTAssertEqual(retrievedMetrics1?.bodyFat, 0.15, "First photo body fat should match")
        
        XCTAssertNotNil(retrievedMetrics2, "Should return metrics for second photo")
        XCTAssertEqual(retrievedMetrics2?.weight, 175.0, "Second photo weight should match")
        XCTAssertEqual(retrievedMetrics2?.bodyFat, 0.12, "Second photo body fat should match")
        
        // When: Getting metrics for non-existent photo
        let nonExistentMetrics = viewModel.getMetricsForPhoto(UUID())
        
        // Then: Should return nil
        XCTAssertNil(nonExistentMetrics, "Should return nil for non-existent photo")
    }
    
    func testPhotoManagement_ComparisonPhotosRetrieval() {
        // Given: A ProgressViewModel with photos and comparison selection
        let photo1 = TestHelpers.createTestProgressPhoto(angle: .front)
        let photo2 = TestHelpers.createTestProgressPhoto(angle: .side)
        let photo3 = TestHelpers.createTestProgressPhoto(angle: .back)
        
        viewModel.photosByAngle = [
            .front: [photo1],
            .side: [photo2],
            .back: [photo3]
        ]
        
        // When: No comparison selection
        viewModel.compareSelection = (nil, nil)
        var (firstPhoto, secondPhoto) = viewModel.comparisonPhotos
        
        // Then: Should return nil for both
        XCTAssertNil(firstPhoto, "First photo should be nil with no selection")
        XCTAssertNil(secondPhoto, "Second photo should be nil with no selection")
        
        // When: Partial selection
        viewModel.compareSelection = (photo1.id, nil)
        (firstPhoto, secondPhoto) = viewModel.comparisonPhotos
        
        // Then: Should return first photo only
        XCTAssertNotNil(firstPhoto, "First photo should not be nil")
        XCTAssertNil(secondPhoto, "Second photo should be nil")
        XCTAssertEqual(firstPhoto?.id, photo1.id, "First photo should match selection")
        
        // When: Full selection
        viewModel.compareSelection = (photo1.id, photo2.id)
        (firstPhoto, secondPhoto) = viewModel.comparisonPhotos
        
        // Then: Should return both photos
        XCTAssertNotNil(firstPhoto, "First photo should not be nil")
        XCTAssertNotNil(secondPhoto, "Second photo should not be nil")
        XCTAssertEqual(firstPhoto?.id, photo1.id, "First photo should match selection")
        XCTAssertEqual(secondPhoto?.id, photo2.id, "Second photo should match selection")
        
        // When: Selection with non-existent photo
        viewModel.compareSelection = (photo1.id, UUID())
        (firstPhoto, secondPhoto) = viewModel.comparisonPhotos
        
        // Then: Should return first photo and nil for second
        XCTAssertNotNil(firstPhoto, "First photo should not be nil")
        XCTAssertNil(secondPhoto, "Second photo should be nil for non-existent ID")
        XCTAssertEqual(firstPhoto?.id, photo1.id, "First photo should match selection")
    }
    
    func testPhotoManagement_MultiplePhotosPerAngle() {
        // Given: A ProgressViewModel with multiple photos per angle
        let frontPhoto1 = TestHelpers.createTestProgressPhoto(date: Date().addingTimeInterval(-86400), angle: .front)
        let frontPhoto2 = TestHelpers.createTestProgressPhoto(date: Date(), angle: .front)
        let sidePhoto1 = TestHelpers.createTestProgressPhoto(date: Date().addingTimeInterval(-172800), angle: .side)
        let sidePhoto2 = TestHelpers.createTestProgressPhoto(date: Date().addingTimeInterval(-43200), angle: .side)
        
        viewModel.photosByAngle = [
            .front: [frontPhoto1, frontPhoto2],
            .side: [sidePhoto1, sidePhoto2],
            .back: []
        ]
        
        // When: Getting photos for angles with multiple photos
        let frontPhotos = viewModel.getPhotosForAngle(.front)
        let sidePhotos = viewModel.getPhotosForAngle(.side)
        let backPhotos = viewModel.getPhotosForAngle(.back)
        
        // Then: Should return all photos for each angle
        XCTAssertEqual(frontPhotos.count, 2, "Should return 2 front photos")
        XCTAssertEqual(sidePhotos.count, 2, "Should return 2 side photos")
        XCTAssertEqual(backPhotos.count, 0, "Should return 0 back photos")
        
        // Verify total photo count
        XCTAssertEqual(viewModel.totalPhotos, 4, "Total photos should be 4")
        
        // Verify latest photo is the most recent
        let latestPhoto = viewModel.latestPhoto
        XCTAssertNotNil(latestPhoto, "Latest photo should not be nil")
        XCTAssertEqual(latestPhoto?.id, frontPhoto2.id, "Latest photo should be the most recent front photo")
    }
}

