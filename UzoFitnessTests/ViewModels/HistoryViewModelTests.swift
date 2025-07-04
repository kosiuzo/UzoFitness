import XCTest
import SwiftData
@testable import UzoFitness

@MainActor
final class HistoryViewModelTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var viewModel: HistoryViewModel!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory model container for testing
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: 
            WorkoutSession.self,
            PerformedExercise.self,
            Exercise.self,
            WorkoutPlan.self,
            WorkoutTemplate.self,
            SessionExercise.self,
            CompletedSet.self,
            DayTemplate.self,
            ExerciseTemplate.self,
            ProgressPhoto.self,
            configurations: config
        )
        
        modelContext = modelContainer.mainContext
        viewModel = HistoryViewModel()
        viewModel.setModelContext(modelContext)
        
        print("✅ [HistoryViewModelTests.setUp] Test environment initialized")
    }
    
    override func tearDown() async throws {
        viewModel = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
        
        print("✅ [HistoryViewModelTests.tearDown] Test environment cleaned up")
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization_SetsDefaultState() async throws {
        // Then
        XCTAssertTrue(viewModel.calendarData.isEmpty)
        XCTAssertNil(viewModel.selectedDate)
        XCTAssertTrue(viewModel.dailyDetails.isEmpty)
        XCTAssertNil(viewModel.error)
        XCTAssertEqual(viewModel.totalVolumeForDay, 0.0)
        XCTAssertNil(viewModel.longestSession)
        XCTAssertEqual(viewModel.streakCount, 0)
        
        print("✅ [HistoryViewModelTests.testInitialization_SetsDefaultState] Passed")
    }
    
    // MARK: - Calendar Data Tests
    
    func testWorkoutSessionSummary_CreatesCorrectSummary() async throws {
        // Given
        let (session, _) = try createTestWorkoutSession(
            date: Date(),
            title: "Morning Workout",
            duration: 3600, // 1 hour
            exerciseCount: 3
        )
        
        // When
        let summary = WorkoutSessionSummary(from: session)
        
        // Then
        XCTAssertEqual(summary.id, session.id)
        XCTAssertEqual(summary.title, "Morning Workout")
        XCTAssertEqual(summary.duration, 3600)
        XCTAssertEqual(summary.exerciseCount, 3)
        XCTAssertEqual(summary.formattedDuration, "1h 0m")
        XCTAssertGreaterThan(summary.totalVolume, 0)
        
        print("✅ [HistoryViewModelTests.testWorkoutSessionSummary_CreatesCorrectSummary] Passed")
    }
    
    func testWorkoutSessionSummary_EmptyTitle_UsesDefaultTitle() async throws {
        // Given
        let (session, _) = try createTestWorkoutSession(
            date: Date(),
            title: "", // Empty title
            duration: 1800,
            exerciseCount: 2
        )
        
        // When
        let summary = WorkoutSessionSummary(from: session)
        
        // Then
        XCTAssertEqual(summary.title, "Workout") // Default title
        XCTAssertEqual(summary.formattedDuration, "30m")
        
        print("✅ [HistoryViewModelTests.testWorkoutSessionSummary_EmptyTitle_UsesDefaultTitle] Passed")
    }
    
    // MARK: - Date Selection Tests
    
    func testSelectDate_WithNoWorkoutData_SetsSelectedDateWithEmptyDetails() async throws {
        // Given
        let futureDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        
        // When
        viewModel.handleIntent(.selectDate(futureDate))
        
        // Then
        XCTAssertNotNil(viewModel.selectedDate)
        XCTAssertTrue(viewModel.dailyDetails.isEmpty)
        XCTAssertTrue(viewModel.selectedDateSessions.isEmpty)
        XCTAssertEqual(viewModel.totalVolumeForDay, 0.0)
        XCTAssertNil(viewModel.longestSession)
        
        print("✅ [HistoryViewModelTests.testSelectDate_WithNoWorkoutData_SetsSelectedDateWithEmptyDetails] Passed")
    }
    
    func testClearSelection_ClearsSelectedDateAndDetails() async throws {
        // Given
        let testDate = Date()
        try createTestWorkoutSession(date: testDate, title: "Test", duration: 3600, exerciseCount: 1)
        viewModel.handleIntent(.loadData)
        viewModel.handleIntent(.selectDate(testDate))
        
        // When
        viewModel.handleIntent(.clearSelection)
        
        // Then
        XCTAssertNil(viewModel.selectedDate)
        XCTAssertTrue(viewModel.dailyDetails.isEmpty)
        XCTAssertTrue(viewModel.selectedDateSessions.isEmpty)
        
        print("✅ [HistoryViewModelTests.testClearSelection_ClearsSelectedDateAndDetails] Passed")
    }
    
    // MARK: - Helper Method Tests
    
    func testHasWorkoutData_WithoutData_ReturnsFalse() async throws {
        // Given
        let futureDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
        
        // When
        let hasData = viewModel.hasWorkoutData(for: futureDate)
        
        // Then
        XCTAssertFalse(hasData)
        
        print("✅ [HistoryViewModelTests.testHasWorkoutData_WithoutData_ReturnsFalse] Passed")
    }
    
    // MARK: - Error Handling Tests
    
    func testClearError_WithError_ClearsError() async throws {
        // Given
        viewModel.error = HistoryError.dataLoadFailed
        
        // When
        viewModel.handleIntent(.clearError)
        
        // Then
        XCTAssertNil(viewModel.error)
        
        print("✅ [HistoryViewModelTests.testClearError_WithError_ClearsError] Passed")
    }
    
    // MARK: - Helper Methods
    
    private func createTestWorkoutSessions() throws -> [WorkoutSession] {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        
        let sessions = [
            try createTestWorkoutSession(date: today, title: "Today's Workout", duration: 3600, exerciseCount: 3).0,
            try createTestWorkoutSession(date: yesterday, title: "Yesterday's Workout", duration: 2700, exerciseCount: 2).0,
            try createTestWorkoutSession(date: twoDaysAgo, title: "Previous Workout", duration: 1800, exerciseCount: 1).0
        ]
        
        return sessions
    }
    
    @discardableResult
    private func createTestWorkoutSession(
        date: Date,
        title: String,
        duration: TimeInterval,
        exerciseCount: Int
    ) throws -> (WorkoutSession, [PerformedExercise]) {
        let session = WorkoutSession(
            date: date,
            title: title,
            duration: duration
        )
        
        modelContext.insert(session)
        
        var performedExercises: [PerformedExercise] = []
        
        for i in 0..<exerciseCount {
            let exercise = Exercise(name: "Exercise \(i + 1)", category: .strength)
            modelContext.insert(exercise)
            
            let sessionExercise = SessionExercise(
                exercise: exercise,
                plannedSets: 3,
                plannedReps: 10,
                position: Double(i + 1),
                session: session
            )
            modelContext.insert(sessionExercise)
            session.sessionExercises.append(sessionExercise)
            
            // Add completed sets
            for setIndex in 0..<2 {
                let completedSet = CompletedSet(
                    reps: 10 + setIndex,
                    weight: 100.0 + Double(setIndex * 10),
                    sessionExercise: sessionExercise
                )
                modelContext.insert(completedSet)
                sessionExercise.completedSets.append(completedSet)
            }
            
            let performedExercise = PerformedExercise(
                reps: 30, // 3 sets x 10 reps
                weight: 100.0 + Double(i * 10),
                exercise: exercise,
                workoutSession: session
            )
            modelContext.insert(performedExercise)
            performedExercises.append(performedExercise)
        }
        
        try modelContext.save()
        
        return (session, performedExercises)
    }
} 