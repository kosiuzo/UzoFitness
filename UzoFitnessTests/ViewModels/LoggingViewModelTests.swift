import XCTest
import SwiftData
@testable import UzoFitness

@MainActor
final class LoggingViewModelTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var viewModel: LoggingViewModel!
    var mockTimerFactory: MockTimerFactory!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory model container for testing
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: 
            WorkoutPlan.self,
            WorkoutSession.self,
            SessionExercise.self,
            CompletedSet.self,
            Exercise.self,
            ExerciseTemplate.self,
            DayTemplate.self,
            WorkoutTemplate.self,
            PerformedExercise.self,
            configurations: config
        )
        modelContext = modelContainer.mainContext
        
        // Create mock timer factory
        mockTimerFactory = MockTimerFactory()
        
        // Initialize view model
        viewModel = LoggingViewModel(modelContext: modelContext, timerFactory: mockTimerFactory)
        
        print("🔄 [LoggingViewModelTests.setUp] Test environment initialized")
    }
    
    override func tearDown() async throws {
        viewModel = nil
        mockTimerFactory = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }
    
    // MARK: - Plan Selection Tests
    
    func testSelectPlan_ValidPlan_SetsActivePlan() async throws {
        // Given
        let workoutTemplate = WorkoutTemplate(name: "Test Template")
        let workoutPlan = WorkoutPlan(customName: "Test Plan", template: workoutTemplate)
        
        modelContext.insert(workoutTemplate)
        modelContext.insert(workoutPlan)
        try modelContext.save()
        
        // When
        viewModel.handleIntent(.selectPlan(workoutPlan.id))
        
        // Then
        XCTAssertNotNil(viewModel.activePlan)
        XCTAssertEqual(viewModel.activePlan?.id, workoutPlan.id)
        XCTAssertEqual(viewModel.activePlan?.customName, "Test Plan")
        
        print("✅ [LoggingViewModelTests.testSelectPlan_ValidPlan_SetsActivePlan] Passed")
    }
    
    func testSelectPlan_InvalidPlan_SetsError() async throws {
        // Given
        let nonExistentID = UUID()
        
        // When
        viewModel.handleIntent(.selectPlan(nonExistentID))
        
        // Then
        XCTAssertNil(viewModel.activePlan)
        XCTAssertNotNil(viewModel.error)
        
        print("✅ [LoggingViewModelTests.testSelectPlan_InvalidPlan_SetsError] Passed")
    }
    
    // MARK: - Day Selection Tests
    
    func testSelectDay_WithActivePlan_SetsSelectedDay() async throws {
        // Given
        let exercise = Exercise(name: "Bench Press", category: .strength)
        let workoutTemplate = WorkoutTemplate(name: "Test Template")
        let dayTemplate = DayTemplate(weekday: .monday, workoutTemplate: workoutTemplate)
        let exerciseTemplate = ExerciseTemplate(
            exercise: exercise,
            setCount: 3,
            reps: 10,
            weight: 135.0,
            position: 1.0,
            dayTemplate: dayTemplate
        )
        
        modelContext.insert(exercise)
        modelContext.insert(workoutTemplate)
        modelContext.insert(dayTemplate)
        modelContext.insert(exerciseTemplate)
        
        workoutTemplate.dayTemplates.append(dayTemplate)
        dayTemplate.exerciseTemplates.append(exerciseTemplate)
        
        let workoutPlan = WorkoutPlan(customName: "Test Plan", template: workoutTemplate)
        modelContext.insert(workoutPlan)
        
        try modelContext.save()
        
        viewModel.handleIntent(.selectPlan(workoutPlan.id))
        
        // When
        viewModel.handleIntent(.selectDay(.monday))
        
        // Then
        XCTAssertNotNil(viewModel.selectedDay)
        XCTAssertEqual(viewModel.selectedDay?.weekday, .monday)
        XCTAssertFalse(viewModel.isRestDay)
        XCTAssertNotNil(viewModel.session)
        XCTAssertEqual(viewModel.exercises.count, 1)
        
        print("✅ [LoggingViewModelTests.testSelectDay_WithActivePlan_SetsSelectedDay] Passed")
    }
    
    func testSelectDay_RestDay_SetsRestDayFlag() async throws {
        // Given
        let workoutTemplate = WorkoutTemplate(name: "Test Template")
        let restDayTemplate = DayTemplate(weekday: .sunday, isRest: true, workoutTemplate: workoutTemplate)
        
        modelContext.insert(workoutTemplate)
        modelContext.insert(restDayTemplate)
        
        workoutTemplate.dayTemplates.append(restDayTemplate)
        
        let workoutPlan = WorkoutPlan(customName: "Test Plan", template: workoutTemplate)
        modelContext.insert(workoutPlan)
        
        try modelContext.save()
        
        viewModel.handleIntent(.selectPlan(workoutPlan.id))
        
        // When
        viewModel.handleIntent(.selectDay(.sunday))
        
        // Then
        XCTAssertNotNil(viewModel.selectedDay)
        XCTAssertEqual(viewModel.selectedDay?.weekday, .sunday)
        XCTAssertTrue(viewModel.isRestDay)
        
        print("✅ [LoggingViewModelTests.testSelectDay_RestDay_SetsRestDayFlag] Passed")
    }
    
    // MARK: - Exercise Interaction Tests
    
    func testAddSet_ValidExercise_AddsCompletedSet() async throws {
        // Given
        let (exercise, session) = try createTestSession()
        let sessionExercise = session.sessionExercises.first!
        let initialSetCount = sessionExercise.completedSets.count
        
        // When
        viewModel.handleIntent(.addSet(exerciseID: sessionExercise.id))
        
        // Then
        XCTAssertEqual(sessionExercise.completedSets.count, initialSetCount + 1)
        XCTAssertEqual(sessionExercise.currentSet, initialSetCount + 1)
        
        print("✅ [LoggingViewModelTests.testAddSet_ValidExercise_AddsCompletedSet] Passed")
    }
    
    func testEditSet_ValidData_UpdatesSet() async throws {
        // Given
        let (exercise, session) = try createTestSession()
        let sessionExercise = session.sessionExercises.first!
        
        // Add a set first
        viewModel.handleIntent(.addSet(exerciseID: sessionExercise.id))
        
        // When
        viewModel.handleIntent(.editSet(exerciseID: sessionExercise.id, setIndex: 0, reps: 12, weight: 150.0))
        
        // Then
        let completedSet = sessionExercise.completedSets.first!
        XCTAssertEqual(completedSet.reps, 12)
        XCTAssertEqual(completedSet.weight, 150.0)
        
        print("✅ [LoggingViewModelTests.testEditSet_ValidData_UpdatesSet] Passed")
    }
    
    func testMarkExerciseComplete_ValidExercise_MarksComplete() async throws {
        // Given
        let (exercise, session) = try createTestSession()
        let sessionExercise = session.sessionExercises.first!
        
        // When
        viewModel.handleIntent(.markExerciseComplete(exerciseID: sessionExercise.id))
        
        // Then
        XCTAssertTrue(sessionExercise.isCompleted)
        
        print("✅ [LoggingViewModelTests.testMarkExerciseComplete_ValidExercise_MarksComplete] Passed")
    }
    
    // MARK: - Timer Tests
    
    func testStartRest_ValidExercise_StartsTimer() async throws {
        // Given
        let (exercise, session) = try createTestSession()
        let sessionExercise = session.sessionExercises.first!
        
        // When
        viewModel.handleIntent(.startRest(exerciseID: sessionExercise.id, seconds: 60))
        
        // Then
        XCTAssertEqual(sessionExercise.restTimer, 60)
        XCTAssertTrue(viewModel.showTimerSheet)
        XCTAssertTrue(mockTimerFactory.timerCreated)
        
        print("✅ [LoggingViewModelTests.testStartRest_ValidExercise_StartsTimer] Passed")
    }
    
    // MARK: - Session Completion Tests
    
    func testCanFinishSession_AllExercisesComplete_ReturnsTrue() async throws {
        // Given
        let (exercise, session) = try createTestSession()
        let sessionExercise = session.sessionExercises.first!
        
        // Mark exercise as complete
        viewModel.handleIntent(.markExerciseComplete(exerciseID: sessionExercise.id))
        
        // When/Then
        XCTAssertTrue(viewModel.canFinishSession)
        
        print("✅ [LoggingViewModelTests.testCanFinishSession_AllExercisesComplete_ReturnsTrue] Passed")
    }
    
    func testCanFinishSession_IncompleteExercises_ReturnsFalse() async throws {
        // Given
        let (exercise, session) = try createTestSession()
        
        // When/Then (exercise is not marked complete)
        XCTAssertFalse(viewModel.canFinishSession)
        
        print("✅ [LoggingViewModelTests.testCanFinishSession_IncompleteExercises_ReturnsFalse] Passed")
    }
    
    func testFinishSession_AllComplete_CreatesPerformedExercises() async throws {
        // Given
        let (exercise, session) = try createTestSession()
        let sessionExercise = session.sessionExercises.first!
        
        // Add a completed set and mark exercise complete
        viewModel.handleIntent(.addSet(exerciseID: sessionExercise.id))
        viewModel.handleIntent(.markExerciseComplete(exerciseID: sessionExercise.id))
        
        let initialPerformedCount = try modelContext.fetch(FetchDescriptor<PerformedExercise>()).count
        
        // When
        viewModel.handleIntent(.finishSession)
        
        // Then
        let finalPerformedCount = try modelContext.fetch(FetchDescriptor<PerformedExercise>()).count
        XCTAssertEqual(finalPerformedCount, initialPerformedCount + 1)
        XCTAssertNil(viewModel.session)
        XCTAssertTrue(viewModel.exercises.isEmpty)
        
        print("✅ [LoggingViewModelTests.testFinishSession_AllComplete_CreatesPerformedExercises] Passed")
    }
    
    // MARK: - Computed Properties Tests
    
    func testTotalVolume_WithCompletedSets_CalculatesCorrectly() async throws {
        // Given
        let (exercise, session) = try createTestSession()
        let sessionExercise = session.sessionExercises.first!
        
        // Add sets with known values
        viewModel.handleIntent(.addSet(exerciseID: sessionExercise.id))
        viewModel.handleIntent(.editSet(exerciseID: sessionExercise.id, setIndex: 0, reps: 10, weight: 100.0))
        
        viewModel.handleIntent(.addSet(exerciseID: sessionExercise.id))
        viewModel.handleIntent(.editSet(exerciseID: sessionExercise.id, setIndex: 1, reps: 8, weight: 105.0))
        
        // When
        let totalVolume = viewModel.totalVolume
        
        // Then
        let expectedVolume = (10 * 100.0) + (8 * 105.0) // 1000 + 840 = 1840
        XCTAssertEqual(totalVolume, expectedVolume, accuracy: 0.01)
        
        print("✅ [LoggingViewModelTests.testTotalVolume_WithCompletedSets_CalculatesCorrectly] Passed")
    }
    
    // MARK: - SessionExerciseUI Tests
    
    func testSessionExerciseUI_SupersetDetection_IdentifiesHeadCorrectly() async throws {
        // Given
        let exercise1 = Exercise(name: "Exercise 1", category: .strength)
        let exercise2 = Exercise(name: "Exercise 2", category: .strength)
        let workoutTemplate = WorkoutTemplate(name: "Test Template")
        let dayTemplate = DayTemplate(weekday: .monday, workoutTemplate: workoutTemplate)
        
        let supersetID = UUID()
        let exerciseTemplate1 = ExerciseTemplate(
            exercise: exercise1,
            setCount: 3,
            reps: 10,
            weight: 135.0,
            position: 1.0,
            supersetID: supersetID,
            dayTemplate: dayTemplate
        )
        let exerciseTemplate2 = ExerciseTemplate(
            exercise: exercise2,
            setCount: 3,
            reps: 10,
            weight: 95.0,
            position: 2.0,
            supersetID: supersetID,
            dayTemplate: dayTemplate
        )
        
        modelContext.insert(exercise1)
        modelContext.insert(exercise2)
        modelContext.insert(workoutTemplate)
        modelContext.insert(dayTemplate)
        modelContext.insert(exerciseTemplate1)
        modelContext.insert(exerciseTemplate2)
        
        workoutTemplate.dayTemplates.append(dayTemplate)
        dayTemplate.exerciseTemplates.append(exerciseTemplate1)
        dayTemplate.exerciseTemplates.append(exerciseTemplate2)
        
        let workoutPlan = WorkoutPlan(customName: "Test Plan", template: workoutTemplate)
        modelContext.insert(workoutPlan)
        
        try modelContext.save()
        
        viewModel.handleIntent(.selectPlan(workoutPlan.id))
        viewModel.handleIntent(.selectDay(.monday))
        
        // When/Then
        XCTAssertEqual(viewModel.exercises.count, 2)
        XCTAssertTrue(viewModel.exercises.first?.isSupersetHead == true)  // First exercise should be superset head
        XCTAssertTrue(viewModel.exercises.last?.isSupersetHead == false)  // Second exercise should not be head
        
        print("✅ [LoggingViewModelTests.testSessionExerciseUI_SupersetDetection_IdentifiesHeadCorrectly] Passed")
    }
    
    // MARK: - Error Handling Tests
    
    func testAddSet_InvalidExerciseID_SetsError() async throws {
        // Given
        let invalidID = UUID()
        
        // When
        viewModel.handleIntent(.addSet(exerciseID: invalidID))
        
        // Then
        XCTAssertNotNil(viewModel.error)
        
        print("✅ [LoggingViewModelTests.testAddSet_InvalidExerciseID_SetsError] Passed")
    }
    
    func testFinishSession_IncompleteExercises_SetsError() async throws {
        // Given
        let (exercise, session) = try createTestSession()
        // Don't mark exercise as complete
        
        // When
        viewModel.handleIntent(.finishSession)
        
        // Then
        XCTAssertNotNil(viewModel.error)
        XCTAssertNotNil(viewModel.session) // Session should still exist
        
        print("✅ [LoggingViewModelTests.testFinishSession_IncompleteExercises_SetsError] Passed")
    }
    
    // MARK: - Helper Methods
    
    private func createTestSession() throws -> (Exercise, WorkoutSession) {
        let exercise = Exercise(name: "Test Exercise", category: .strength)
        let workoutTemplate = WorkoutTemplate(name: "Test Template")
        let dayTemplate = DayTemplate(weekday: .monday, workoutTemplate: workoutTemplate)
        let exerciseTemplate = ExerciseTemplate(
            exercise: exercise,
            setCount: 3,
            reps: 10,
            weight: 135.0,
            position: 1.0,
            dayTemplate: dayTemplate
        )
        
        modelContext.insert(exercise)
        modelContext.insert(workoutTemplate)
        modelContext.insert(dayTemplate)
        modelContext.insert(exerciseTemplate)
        
        workoutTemplate.dayTemplates.append(dayTemplate)
        dayTemplate.exerciseTemplates.append(exerciseTemplate)
        
        let workoutPlan = WorkoutPlan(customName: "Test Plan", template: workoutTemplate)
        modelContext.insert(workoutPlan)
        
        try modelContext.save()
        
        viewModel.handleIntent(.selectPlan(workoutPlan.id))
        viewModel.handleIntent(.selectDay(.monday))
        
        return (exercise, viewModel.session!)
    }
}

// MARK: - Mock TimerFactory
class MockTimerFactory: TimerFactory {
    var timerCreated = false
    var mockTimer: MockTimer?
    
    func createTimer(interval: TimeInterval, repeats: Bool, block: @escaping (Timer) -> Void) -> Timer {
        timerCreated = true
        mockTimer = MockTimer(block: block)
        return mockTimer!
    }
}

// MARK: - Mock Timer
class MockTimer: Timer {
    private let block: (Timer) -> Void
    private var isValidFlag = true
    
    init(block: @escaping (Timer) -> Void) {
        self.block = block
        super.init()
    }
    
    override func invalidate() {
        isValidFlag = false
    }
    
    override var isValid: Bool {
        return isValidFlag
    }
    
    override func fire() {
        if isValidFlag {
            block(self)
        }
    }
} 