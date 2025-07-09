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
        XCTAssertTrue(viewModel.workoutSessions.isEmpty)
        XCTAssertNil(viewModel.selectedDate)
        XCTAssertNil(viewModel.error)
        XCTAssertEqual(viewModel.streakCount, 0)
        XCTAssertEqual(viewModel.totalWorkoutDays, 0)
        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertFalse(viewModel.isLoading)
        
        print("✅ [HistoryViewModelTests.testInitialization_SetsDefaultState] Passed")
    }
    
    // MARK: - Data Loading Tests
    
    func testLoadWorkoutData_LoadsSessionsWithCompletedSets() async throws {
        // Given
        let (session, _) = try createTestWorkoutSession(
            date: Date(),
            title: "Morning Workout",
            duration: 3600, // 1 hour
            exerciseCount: 3
        )
        
        // When
        viewModel.handleIntent(.loadData)
        
        // Then
        XCTAssertEqual(viewModel.workoutSessions.count, 1)
        XCTAssertEqual(viewModel.workoutSessions.first?.title, "Morning Workout")
        XCTAssertEqual(viewModel.workoutSessions.first?.duration, 3600)
        XCTAssertEqual(viewModel.workoutSessions.first?.sessionExercises.count, 3)
        XCTAssertGreaterThan(viewModel.workoutSessions.first?.totalVolume ?? 0, 0)
        
        print("✅ [HistoryViewModelTests.testLoadWorkoutData_LoadsSessionsWithCompletedSets] Passed")
    }
    
    func testLoadWorkoutData_HandlesEmptyTitle() async throws {
        // Given
        let (session, _) = try createTestWorkoutSession(
            date: Date(),
            title: "", // Empty title
            duration: 1800,
            exerciseCount: 2
        )
        
        // When
        viewModel.handleIntent(.loadData)
        
        // Then
        XCTAssertEqual(viewModel.workoutSessions.count, 1)
        XCTAssertEqual(viewModel.workoutSessions.first?.title, "")
        XCTAssertEqual(viewModel.workoutSessions.first?.duration, 1800)
        
        print("✅ [HistoryViewModelTests.testLoadWorkoutData_HandlesEmptyTitle] Passed")
    }
    
    // MARK: - Date Selection Tests
    
    func testSelectDate_WithNoWorkoutData_SetsSelectedDate() async throws {
        // Given
        let futureDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        
        // When
        viewModel.handleIntent(.selectDate(futureDate))
        
        // Then
        XCTAssertNotNil(viewModel.selectedDate)
        XCTAssertTrue(viewModel.sessionsForDate(futureDate).isEmpty)
        
        print("✅ [HistoryViewModelTests.testSelectDate_WithNoWorkoutData_SetsSelectedDate] Passed")
    }
    
    func testClearSelection_ClearsSelectedDate() async throws {
        // Given
        let testDate = Date()
        try createTestWorkoutSession(date: testDate, title: "Test", duration: 3600, exerciseCount: 1)
        viewModel.handleIntent(.loadData)
        viewModel.handleIntent(.selectDate(testDate))
        
        // When
        viewModel.handleIntent(.clearSelection)
        
        // Then
        XCTAssertNil(viewModel.selectedDate)
        
        print("✅ [HistoryViewModelTests.testClearSelection_ClearsSelectedDate] Passed")
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
    
    // MARK: - Completed Sets Bug Fix Tests
    
    func testLoadWorkoutData_FiltersOutSessionsWithNoCompletedSets() async throws {
        // Given: Create a session with only auto-populated values (no completed sets)
        let sessionWithNoCompletedSets = WorkoutSession(
            date: Date(),
            title: "Empty Session",
            duration: 1800
        )
        modelContext.insert(sessionWithNoCompletedSets)
        
        let exercise = Exercise(name: "Bench Press", category: .strength)
        modelContext.insert(exercise)
        
        let sessionExercise = SessionExercise(
            exercise: exercise,
            plannedSets: 3,
            plannedReps: 10,
            position: 1.0,
            session: sessionWithNoCompletedSets
        )
        modelContext.insert(sessionExercise)
        sessionWithNoCompletedSets.sessionExercises.append(sessionExercise)
        
        // No completed sets added intentionally
        
        // And: Create a session with actual completed sets
        let sessionWithCompletedSets = WorkoutSession(
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            title: "Completed Session",
            duration: 2400
        )
        modelContext.insert(sessionWithCompletedSets)
        
        let exercise2 = Exercise(name: "Squat", category: .strength)
        modelContext.insert(exercise2)
        
        let sessionExercise2 = SessionExercise(
            exercise: exercise2,
            plannedSets: 3,
            plannedReps: 10,
            position: 1.0,
            session: sessionWithCompletedSets
        )
        modelContext.insert(sessionExercise2)
        sessionWithCompletedSets.sessionExercises.append(sessionExercise2)
        
        // Add completed sets
        let completedSet1 = CompletedSet(
            reps: 10,
            weight: 135.0,
            position: 0,
            sessionExercise: sessionExercise2
        )
        let completedSet2 = CompletedSet(
            reps: 8,
            weight: 135.0,
            position: 1,
            sessionExercise: sessionExercise2
        )
        modelContext.insert(completedSet1)
        modelContext.insert(completedSet2)
        sessionExercise2.completedSets.append(completedSet1)
        sessionExercise2.completedSets.append(completedSet2)
        
        try modelContext.save()
        
        // When
        viewModel.handleIntent(.loadData)
        
        // Then: Only session with completed sets should be loaded
        XCTAssertEqual(viewModel.workoutSessions.count, 1)
        XCTAssertEqual(viewModel.workoutSessions.first?.title, "Completed Session")
        XCTAssertEqual(viewModel.workoutSessions.first?.sessionExercises.first?.completedSets.count, 2)
        
        print("✅ [HistoryViewModelTests.testLoadWorkoutData_FiltersOutSessionsWithNoCompletedSets] Passed")
    }
    
    func testLoadWorkoutData_IncludesSessionsWithMixedCompletedSets() async throws {
        // Given: Create a session with multiple exercises, some with completed sets and some without
        let session = WorkoutSession(
            date: Date(),
            title: "Mixed Session",
            duration: 3000
        )
        modelContext.insert(session)
        
        // Exercise 1: Has completed sets
        let exercise1 = Exercise(name: "Bench Press", category: .strength)
        modelContext.insert(exercise1)
        
        let sessionExercise1 = SessionExercise(
            exercise: exercise1,
            plannedSets: 3,
            plannedReps: 10,
            position: 1.0,
            session: session
        )
        modelContext.insert(sessionExercise1)
        session.sessionExercises.append(sessionExercise1)
        
        let completedSet1 = CompletedSet(
            reps: 10,
            weight: 135.0,
            position: 0,
            sessionExercise: sessionExercise1
        )
        modelContext.insert(completedSet1)
        sessionExercise1.completedSets.append(completedSet1)
        
        // Exercise 2: No completed sets (auto-populated only)
        let exercise2 = Exercise(name: "Squat", category: .strength)
        modelContext.insert(exercise2)
        
        let sessionExercise2 = SessionExercise(
            exercise: exercise2,
            plannedSets: 3,
            plannedReps: 10,
            position: 2.0,
            session: session
        )
        modelContext.insert(sessionExercise2)
        session.sessionExercises.append(sessionExercise2)
        // No completed sets added for this exercise
        
        try modelContext.save()
        
        // When
        viewModel.handleIntent(.loadData)
        
        // Then: Session should be included because it has at least one exercise with completed sets
        XCTAssertEqual(viewModel.workoutSessions.count, 1)
        XCTAssertEqual(viewModel.workoutSessions.first?.title, "Mixed Session")
        XCTAssertEqual(viewModel.workoutSessions.first?.sessionExercises.count, 2)
        
        // Verify one exercise has completed sets and one doesn't
        let loadedSession = viewModel.workoutSessions.first!
        let exerciseWithSets = loadedSession.sessionExercises.first { !$0.completedSets.isEmpty }
        let exerciseWithoutSets = loadedSession.sessionExercises.first { $0.completedSets.isEmpty }
        
        XCTAssertNotNil(exerciseWithSets)
        XCTAssertNotNil(exerciseWithoutSets)
        XCTAssertEqual(exerciseWithSets?.completedSets.count, 1)
        XCTAssertEqual(exerciseWithoutSets?.completedSets.count, 0)
        
        print("✅ [HistoryViewModelTests.testLoadWorkoutData_IncludesSessionsWithMixedCompletedSets] Passed")
    }
    
    func testLoadWorkoutData_FiltersOutSessionsWithOnlyAutoPopulatedExercises() async throws {
        // Given: Create multiple sessions with only auto-populated exercises
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        // Session 1: Only auto-populated exercises
        let session1 = WorkoutSession(
            date: today,
            title: "Auto-populated Session 1",
            duration: 1800
        )
        modelContext.insert(session1)
        
        let exercise1 = Exercise(name: "Bench Press", category: .strength)
        modelContext.insert(exercise1)
        
        let sessionExercise1 = SessionExercise(
            exercise: exercise1,
            plannedSets: 3,
            plannedReps: 10,
            position: 1.0,
            session: session1
        )
        modelContext.insert(sessionExercise1)
        session1.sessionExercises.append(sessionExercise1)
        
        // Session 2: Only auto-populated exercises
        let session2 = WorkoutSession(
            date: yesterday,
            title: "Auto-populated Session 2",
            duration: 2400
        )
        modelContext.insert(session2)
        
        let exercise2 = Exercise(name: "Squat", category: .strength)
        modelContext.insert(exercise2)
        
        let sessionExercise2 = SessionExercise(
            exercise: exercise2,
            plannedSets: 4,
            plannedReps: 8,
            position: 1.0,
            session: session2
        )
        modelContext.insert(sessionExercise2)
        session2.sessionExercises.append(sessionExercise2)
        
        try modelContext.save()
        
        // When
        viewModel.handleIntent(.loadData)
        
        // Then: No sessions should be loaded
        XCTAssertEqual(viewModel.workoutSessions.count, 0)
        XCTAssertEqual(viewModel.totalWorkoutDays, 0)
        XCTAssertEqual(viewModel.streakCount, 0)
        
        print("✅ [HistoryViewModelTests.testLoadWorkoutData_FiltersOutSessionsWithOnlyAutoPopulatedExercises] Passed")
    }
    
    func testWorkoutDates_OnlyIncludesSessionsWithCompletedSets() async throws {
        // Given: Create sessions with and without completed sets
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        // Session with completed sets
        let completedSession = WorkoutSession(
            date: today,
            title: "Completed Session",
            duration: 1800
        )
        modelContext.insert(completedSession)
        
        let exercise1 = Exercise(name: "Bench Press", category: .strength)
        modelContext.insert(exercise1)
        
        let sessionExercise1 = SessionExercise(
            exercise: exercise1,
            plannedSets: 3,
            plannedReps: 10,
            position: 1.0,
            session: completedSession
        )
        modelContext.insert(sessionExercise1)
        completedSession.sessionExercises.append(sessionExercise1)
        
        let completedSet = CompletedSet(
            reps: 10,
            weight: 135.0,
            position: 0,
            sessionExercise: sessionExercise1
        )
        modelContext.insert(completedSet)
        sessionExercise1.completedSets.append(completedSet)
        
        // Session without completed sets
        let incompleteSession = WorkoutSession(
            date: yesterday,
            title: "Incomplete Session",
            duration: 1200
        )
        modelContext.insert(incompleteSession)
        
        let exercise2 = Exercise(name: "Squat", category: .strength)
        modelContext.insert(exercise2)
        
        let sessionExercise2 = SessionExercise(
            exercise: exercise2,
            plannedSets: 3,
            plannedReps: 10,
            position: 1.0,
            session: incompleteSession
        )
        modelContext.insert(sessionExercise2)
        incompleteSession.sessionExercises.append(sessionExercise2)
        
        try modelContext.save()
        
        // When
        viewModel.handleIntent(.loadData)
        
        // Then: Only the date with completed sets should be in workoutDates
        XCTAssertEqual(viewModel.workoutDates.count, 1)
        XCTAssertTrue(viewModel.workoutDates.contains(calendar.startOfDay(for: today)))
        XCTAssertFalse(viewModel.workoutDates.contains(calendar.startOfDay(for: yesterday)))
        
        print("✅ [HistoryViewModelTests.testWorkoutDates_OnlyIncludesSessionsWithCompletedSets] Passed")
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