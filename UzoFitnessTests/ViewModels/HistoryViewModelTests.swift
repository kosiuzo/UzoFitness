import XCTest
import SwiftData
import UzoFitnessCore
@testable import UzoFitness

@MainActor
class HistoryViewModelTests: XCTestCase {
    
    // MARK: - Test Properties
    private var persistenceController: InMemoryPersistenceController!
    private var viewModel: HistoryViewModel!
    
    // MARK: - Setup and Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory persistence controller
        persistenceController = InMemoryPersistenceController()
        
        // Create view model with test context
        viewModel = HistoryViewModel(modelContext: persistenceController.context)
        
        // Wait for initial setup
        await TestHelpers.wait(seconds: 0.1)
    }
    
    override func tearDown() async throws {
        // Clean up test data
        persistenceController.cleanupTestData()
        viewModel = nil
        persistenceController = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization_SetsDefaultState() {
        // Given: A newly initialized HistoryViewModel
        // (viewModel created in setUp)
        
        // Then: Default state should be set correctly
        XCTAssertEqual(viewModel.allWorkoutSessions.count, 0, "Should start with empty workout sessions")
        XCTAssertNil(viewModel.selectedDate, "No date should be selected initially")
        XCTAssertFalse(viewModel.isLoading, "Should not be loading initially")
        XCTAssertNil(viewModel.error, "No error should be present initially")
        XCTAssertNotNil(viewModel.modelContext, "Model context should be set")
    }
    
    func testInitialization_ComputedPropertiesWithEmptyData() {
        // Given: A newly initialized HistoryViewModel with no data
        // (viewModel created in setUp)
        
        // Then: Computed properties should handle empty state gracefully
        XCTAssertEqual(viewModel.sessionsForSelectedDate.count, 0, "Should return empty array when no date selected")
        XCTAssertEqual(viewModel.workoutDates.count, 0, "Should return empty set with no workout data")
        XCTAssertEqual(viewModel.streakCount, 0, "Should return zero streak with no workout data")
        XCTAssertEqual(viewModel.totalWorkoutDays, 0, "Should return zero total days with no workout data")
    }
    
    func testInitialization_CalendarDataInitialization() {
        // Given: A newly initialized HistoryViewModel
        // (viewModel created in setUp)
        
        // When: Accessing calendar-related functionality
        let testDate = Date()
        let hasWorkout = viewModel.hasWorkoutData(for: testDate)
        
        // Then: Calendar functionality should work without crashing
        XCTAssertFalse(hasWorkout, "Should return false for dates with no workout data")
        // The calendar should be properly initialized (internal property, verified through behavior)
    }
    
    func testInitialization_DependencyInjection() {
        // Given: A custom model context
        let customPersistenceController = InMemoryPersistenceController()
        
        // When: Creating a view model with the custom context
        let customViewModel = HistoryViewModel(modelContext: customPersistenceController.context)
        
        // Then: The view model should use the injected context
        XCTAssertNotNil(customViewModel.modelContext, "Model context should be injected")
        XCTAssertEqual(customViewModel.allWorkoutSessions.count, 0, "Should start with empty state")
        XCTAssertNil(customViewModel.error, "No error should occur with valid context")
    }
    
    func testInitialization_StateConsistency() {
        // Given: A newly initialized HistoryViewModel
        // (viewModel created in setUp)
        
        // Then: All state properties should be consistent
        XCTAssertEqual(viewModel.allWorkoutSessions.count, 0, "Workout sessions should be empty initially")
        XCTAssertEqual(viewModel.sessionsForSelectedDate.count, 0, "Selected date sessions should be empty")
        XCTAssertEqual(viewModel.workoutDates.count, 0, "Workout dates should be empty")
        
        // Computed properties should not crash
        let _ = viewModel.streakCount // Should not crash
        let _ = viewModel.totalWorkoutDays // Should not crash
        let _ = viewModel.hasWorkoutData(for: Date()) // Should not crash
    }
    
    func testInitialization_LoadsWithExistingData() async {
        // Given: A persistence controller with existing workout data
        let testSession = TestHelpers.createTestWorkoutSession(date: Date())
        let testExercise = TestHelpers.createTestExercise(name: "Test Exercise")
        let testSessionExercise = TestHelpers.createTestSessionExercise(exercise: testExercise)
        testSessionExercise.session = testSession
        
        persistenceController.create(testSession)
        persistenceController.create(testExercise)
        persistenceController.create(testSessionExercise)
        
        // When: Creating a new view model and loading data
        let newViewModel = HistoryViewModel(modelContext: persistenceController.context)
        await newViewModel.loadWorkoutSessions()
        
        // Then: Existing data should be loaded
        XCTAssertGreaterThan(newViewModel.allWorkoutSessions.count, 0, "Should load existing workout sessions")
        XCTAssertFalse(newViewModel.isLoading, "Should not be loading after completion")
        XCTAssertNil(newViewModel.error, "No error should occur with valid data")
    }
    
    func testInitialization_DefaultStateSetup() {
        // Given: A newly initialized HistoryViewModel
        // (viewModel created in setUp)
        
        // Then: Default state should be properly configured
        XCTAssertFalse(viewModel.isLoading, "Loading state should be false initially")
        XCTAssertNil(viewModel.error, "Error should be nil initially")
        XCTAssertNil(viewModel.selectedDate, "Selected date should be nil initially")
        XCTAssertEqual(viewModel.allWorkoutSessions, [], "Workout sessions should be empty array initially")
        
        // Verify that the model context is functional
        XCTAssertNoThrow(try viewModel.modelContext.save(), "Model context should be functional")
    }
    
    // MARK: - Workout Summary Tests
    
    func testWorkoutSummary_WithNoData_ReturnsDefaultValues() {
        // Given: A HistoryViewModel with no workout data
        // (viewModel created in setUp with empty data)
        
        // Then: Summary calculations should return default values
        XCTAssertEqual(viewModel.streakCount, 0, "Streak count should be 0 with no data")
        XCTAssertEqual(viewModel.totalWorkoutDays, 0, "Total workout days should be 0 with no data")
        XCTAssertEqual(viewModel.workoutDates.count, 0, "Workout dates should be empty with no data")
    }
    
    func testWorkoutSummary_WithSingleWorkout_CalculatesCorrectly() async {
        // Given: A HistoryViewModel with one workout session
        let testDate = Date()
        let testSession = TestHelpers.createTestWorkoutSession(date: testDate)
        let testExercise = TestHelpers.createTestExercise(name: "Test Exercise")
        let testSessionExercise = TestHelpers.createTestSessionExercise(exercise: testExercise)
        testSessionExercise.session = testSession
        
        persistenceController.create(testSession)
        persistenceController.create(testExercise)
        persistenceController.create(testSessionExercise)
        
        // When: Loading workout data
        await viewModel.loadWorkoutSessions()
        
        // Then: Summary should reflect single workout
        XCTAssertEqual(viewModel.totalWorkoutDays, 1, "Should count one workout day")
        XCTAssertEqual(viewModel.workoutDates.count, 1, "Should have one workout date")
        XCTAssertTrue(viewModel.workoutDates.contains { Calendar.current.isDate($0, inSameDayAs: testDate) }, "Should contain test date")
    }
    
    func testWorkoutSummary_WithMultipleWorkouts_CalculatesCorrectly() async {
        // Given: A HistoryViewModel with multiple workout sessions
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: today)!
        
        let session1 = TestHelpers.createTestWorkoutSession(date: today)
        let session2 = TestHelpers.createTestWorkoutSession(date: yesterday)
        let session3 = TestHelpers.createTestWorkoutSession(date: twoDaysAgo)
        
        let testExercise = TestHelpers.createTestExercise(name: "Test Exercise")
        
        // Add session exercises to make sessions valid
        let sessionEx1 = TestHelpers.createTestSessionExercise(exercise: testExercise)
        sessionEx1.session = session1
        let sessionEx2 = TestHelpers.createTestSessionExercise(exercise: testExercise)
        sessionEx2.session = session2
        let sessionEx3 = TestHelpers.createTestSessionExercise(exercise: testExercise)
        sessionEx3.session = session3
        
        persistenceController.create(testExercise)
        persistenceController.create(session1)
        persistenceController.create(session2)
        persistenceController.create(session3)
        persistenceController.create(sessionEx1)
        persistenceController.create(sessionEx2)
        persistenceController.create(sessionEx3)
        
        // When: Loading workout data
        await viewModel.loadWorkoutSessions()
        
        // Then: Summary should reflect multiple workouts
        XCTAssertEqual(viewModel.totalWorkoutDays, 3, "Should count three workout days")
        XCTAssertEqual(viewModel.workoutDates.count, 3, "Should have three workout dates")
        XCTAssertGreaterThanOrEqual(viewModel.streakCount, 1, "Should have at least a streak of 1")
    }
    
    func testWorkoutSummary_HandlesNilValues() {
        // Given: A HistoryViewModel with potentially nil data
        viewModel.allWorkoutSessions = []
        
        // When: Accessing summary properties
        let streak = viewModel.streakCount
        let totalDays = viewModel.totalWorkoutDays
        let workoutDates = viewModel.workoutDates
        
        // Then: Should handle nil/empty values gracefully
        XCTAssertEqual(streak, 0, "Streak should be 0 for empty data")
        XCTAssertEqual(totalDays, 0, "Total days should be 0 for empty data")
        XCTAssertEqual(workoutDates.count, 0, "Workout dates should be empty for empty data")
    }
    
    // MARK: - Date Selection Tests
    
    func testDateSelection_SelectValidDate_UpdatesSelectedDate() {
        // Given: A HistoryViewModel and a test date
        let testDate = Date()
        
        // When: Selecting a date
        viewModel.selectDate(testDate)
        
        // Then: Selected date should be updated
        XCTAssertNotNil(viewModel.selectedDate, "Selected date should not be nil")
        XCTAssertTrue(Calendar.current.isDate(viewModel.selectedDate!, inSameDayAs: testDate), "Selected date should match test date")
    }
    
    func testDateSelection_WithWorkoutData_FiltersCorrectly() async {
        // Given: A HistoryViewModel with workout data on specific dates
        let targetDate = Date()
        let otherDate = Calendar.current.date(byAdding: .day, value: -1, to: targetDate)!
        
        let sessionOnTarget = TestHelpers.createTestWorkoutSession(date: targetDate)
        let sessionOnOther = TestHelpers.createTestWorkoutSession(date: otherDate)
        
        let testExercise = TestHelpers.createTestExercise(name: "Test Exercise")
        let sessionEx1 = TestHelpers.createTestSessionExercise(exercise: testExercise)
        sessionEx1.session = sessionOnTarget
        let sessionEx2 = TestHelpers.createTestSessionExercise(exercise: testExercise)
        sessionEx2.session = sessionOnOther
        
        persistenceController.create(testExercise)
        persistenceController.create(sessionOnTarget)
        persistenceController.create(sessionOnOther)
        persistenceController.create(sessionEx1)
        persistenceController.create(sessionEx2)
        
        await viewModel.loadWorkoutSessions()
        
        // When: Selecting the target date
        viewModel.selectDate(targetDate)
        
        // Then: Should return only sessions for selected date
        XCTAssertEqual(viewModel.sessionsForSelectedDate.count, 1, "Should return one session for target date")
        XCTAssertTrue(Calendar.current.isDate(viewModel.sessionsForSelectedDate.first!.date, inSameDayAs: targetDate), "Returned session should be for target date")
    }
    
    func testDateSelection_EmptyState_HandlesGracefully() {
        // Given: A HistoryViewModel with no workout data
        let testDate = Date()
        
        // When: Selecting a date with no data
        viewModel.selectDate(testDate)
        
        // Then: Should handle empty state gracefully
        XCTAssertNotNil(viewModel.selectedDate, "Selected date should be set")
        XCTAssertEqual(viewModel.sessionsForSelectedDate.count, 0, "Should return empty array for date with no data")
        XCTAssertFalse(viewModel.hasWorkoutData(for: testDate), "Should return false for date with no workout data")
    }
    
    func testDateSelection_NilSelectedDate_ReturnsEmptyArray() {
        // Given: A HistoryViewModel with nil selected date
        viewModel.selectedDate = nil
        
        // When: Accessing sessions for selected date
        let sessions = viewModel.sessionsForSelectedDate
        
        // Then: Should return empty array
        XCTAssertEqual(sessions.count, 0, "Should return empty array when no date is selected")
    }
    
    func testDateSelection_MultipleSessionsSameDay_ReturnsAll() async {
        // Given: Multiple workout sessions on the same day
        let targetDate = Date()
        let session1 = TestHelpers.createTestWorkoutSession(date: targetDate)
        let session2 = TestHelpers.createTestWorkoutSession(date: targetDate)
        
        let testExercise = TestHelpers.createTestExercise(name: "Test Exercise")
        let sessionEx1 = TestHelpers.createTestSessionExercise(exercise: testExercise)
        sessionEx1.session = session1
        let sessionEx2 = TestHelpers.createTestSessionExercise(exercise: testExercise)
        sessionEx2.session = session2
        
        persistenceController.create(testExercise)
        persistenceController.create(session1)
        persistenceController.create(session2)
        persistenceController.create(sessionEx1)
        persistenceController.create(sessionEx2)
        
        await viewModel.loadWorkoutSessions()
        
        // When: Selecting the date
        viewModel.selectDate(targetDate)
        
        // Then: Should return both sessions
        XCTAssertEqual(viewModel.sessionsForSelectedDate.count, 2, "Should return both sessions for the same day")
    }
}