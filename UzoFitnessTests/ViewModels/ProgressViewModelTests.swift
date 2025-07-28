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
}

