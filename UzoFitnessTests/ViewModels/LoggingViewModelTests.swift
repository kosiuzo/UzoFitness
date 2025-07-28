import XCTest
import SwiftData
import UzoFitnessCore
@testable import UzoFitness

@MainActor
class LoggingViewModelTests: XCTestCase {
    
    // MARK: - Test Properties
    private var persistenceController: InMemoryPersistenceController!
    private var viewModel: LoggingViewModel!
    private var mockTimerFactory: MockTimerFactory!
    
    // MARK: - Setup and Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory persistence controller
        persistenceController = InMemoryPersistenceController()
        
        // Create mock timer factory
        mockTimerFactory = MockTimerFactory()
        
        // Create view model with test dependencies
        viewModel = LoggingViewModel(
            modelContext: persistenceController.context,
            timerFactory: mockTimerFactory
        )
        
        // Wait for initial setup
        await TestHelpers.wait(seconds: 0.1)
    }
    
    override func tearDown() async throws {
        // Clean up test data
        persistenceController.cleanupTestData()
        viewModel = nil
        mockTimerFactory = nil
        persistenceController = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Plan Selection Tests
    
    func testPlanSelection_ValidPlan_UpdatesActivePlan() {
        // Given: A LoggingViewModel and a test workout plan
        let testTemplate = TestHelpers.createTestWorkoutTemplate(name: "Test Template")
        let testPlan = TestHelpers.createTestWorkoutPlan(customName: "Test Plan", template: testTemplate)
        
        persistenceController.create(testTemplate)
        persistenceController.create(testPlan)
        
        // Reload plans to populate availablePlans
        viewModel.loadAvailablePlans()
        
        // When: Selecting the plan
        viewModel.handleIntent(.selectPlan(testPlan.id))
        
        // Then: Active plan should be updated
        XCTAssertNotNil(viewModel.activePlan, "Active plan should be set")
        XCTAssertEqual(viewModel.activePlan?.id, testPlan.id, "Active plan should match selected plan")
        XCTAssertEqual(viewModel.activePlan?.customName, "Test Plan", "Active plan name should match")
        XCTAssertNil(viewModel.error, "No error should occur with valid plan")
    }
    
    func testPlanSelection_InvalidPlanID_SetsError() {
        // Given: A LoggingViewModel and an invalid plan ID
        let invalidPlanID = UUID()
        
        // When: Selecting a non-existent plan
        viewModel.handleIntent(.selectPlan(invalidPlanID))
        
        // Then: Error should be set and no plan selected
        XCTAssertNil(viewModel.activePlan, "No plan should be selected")
        XCTAssertNotNil(viewModel.error, "Error should be set for invalid plan ID")
        
        if let error = viewModel.error as? LoggingError {
            switch error {
            case .noPlanSelected:
                break // Expected error type
            default:
                XCTFail("Expected noPlanSelected error but got \(error)")
            }
        }
    }
    
    func testPlanSelection_LoadsAvailableDays() {
        // Given: A LoggingViewModel with a workout plan containing day templates
        let testTemplate = TestHelpers.createTestWorkoutTemplate(name: "Test Template")
        let testPlan = TestHelpers.createTestWorkoutPlan(customName: "Test Plan", template: testTemplate)
        let mondayTemplate = TestHelpers.createTestDayTemplate(weekday: .monday, workoutTemplate: testTemplate)
        let wednesdayTemplate = TestHelpers.createTestDayTemplate(weekday: .wednesday, workoutTemplate: testTemplate)
        
        persistenceController.create(testTemplate)
        persistenceController.create(testPlan)
        persistenceController.create(mondayTemplate)
        persistenceController.create(wednesdayTemplate)
        
        viewModel.loadAvailablePlans()
        
        // When: Selecting the plan
        viewModel.handleIntent(.selectPlan(testPlan.id))
        
        // Then: Available days should be loaded
        XCTAssertGreaterThan(viewModel.availableDays.count, 0, "Available days should be loaded")
        XCTAssertTrue(viewModel.availableDays.contains { $0.weekday == .monday }, "Should contain Monday")
        XCTAssertTrue(viewModel.availableDays.contains { $0.weekday == .wednesday }, "Should contain Wednesday")
    }
    
    func testPlanSelection_AutoSelectsCurrentDay() {
        // Given: A LoggingViewModel with a plan containing today's weekday
        let today = Calendar.current.component(.weekday, from: Date())
        guard let todayWeekday = Weekday(rawValue: today) else {
            XCTFail("Unable to determine today's weekday")
            return
        }
        
        let testTemplate = TestHelpers.createTestWorkoutTemplate(name: "Test Template")
        let testPlan = TestHelpers.createTestWorkoutPlan(customName: "Test Plan", template: testTemplate)
        let todayTemplate = TestHelpers.createTestDayTemplate(weekday: todayWeekday, workoutTemplate: testTemplate)
        
        persistenceController.create(testTemplate)
        persistenceController.create(testPlan)
        persistenceController.create(todayTemplate)
        
        viewModel.loadAvailablePlans()
        
        // When: Selecting the plan
        viewModel.handleIntent(.selectPlan(testPlan.id))
        
        // Then: Today should be auto-selected
        XCTAssertNotNil(viewModel.selectedDay, "Today should be auto-selected")
        XCTAssertEqual(viewModel.selectedDay?.weekday, todayWeekday, "Selected day should be today")
    }
    
    func testPlanSelection_ClearsSessionState() {
        // Given: A LoggingViewModel with an active session
        viewModel.session = TestHelpers.createTestWorkoutSession(date: Date())
        viewModel.isWorkoutInProgress = true
        
        let testTemplate = TestHelpers.createTestWorkoutTemplate(name: "New Template")
        let testPlan = TestHelpers.createTestWorkoutPlan(customName: "New Plan", template: testTemplate)
        
        persistenceController.create(testTemplate)
        persistenceController.create(testPlan)
        viewModel.loadAvailablePlans()
        
        // When: Selecting a different plan
        viewModel.handleIntent(.selectPlan(testPlan.id))
        
        // Then: Session state should be cleared
        XCTAssertNil(viewModel.session, "Session should be cleared when selecting new plan")
        XCTAssertFalse(viewModel.isWorkoutInProgress, "Workout should not be in progress")
    }
    
    // MARK: - Day Selection Tests
    
    func testDaySelection_ValidDay_UpdatesSelectedDay() {
        // Given: A LoggingViewModel with available days
        let testTemplate = TestHelpers.createTestWorkoutTemplate(name: "Test Template")
        let testPlan = TestHelpers.createTestWorkoutPlan(customName: "Test Plan", template: testTemplate)
        let mondayTemplate = TestHelpers.createTestDayTemplate(weekday: .monday, workoutTemplate: testTemplate)
        
        persistenceController.create(testTemplate)
        persistenceController.create(testPlan)
        persistenceController.create(mondayTemplate)
        
        viewModel.loadAvailablePlans()
        viewModel.handleIntent(.selectPlan(testPlan.id))
        
        // When: Selecting Monday
        viewModel.handleIntent(.selectDay(.monday))
        
        // Then: Selected day should be updated
        XCTAssertNotNil(viewModel.selectedDay, "Selected day should be set")
        XCTAssertEqual(viewModel.selectedDay?.weekday, .monday, "Selected day should be Monday")
        XCTAssertFalse(viewModel.isRestDay, "Monday should not be a rest day")
        XCTAssertNil(viewModel.error, "No error should occur with valid day")
    }
    
    func testDaySelection_RestDay_SetsRestDayFlag() {
        // Given: A LoggingViewModel with a plan that doesn't include Tuesday
        let testTemplate = TestHelpers.createTestWorkoutTemplate(name: "Test Template")
        let testPlan = TestHelpers.createTestWorkoutPlan(customName: "Test Plan", template: testTemplate)
        let mondayTemplate = TestHelpers.createTestDayTemplate(weekday: .monday, workoutTemplate: testTemplate)
        // Note: Not creating Tuesday template, so it should be a rest day
        
        persistenceController.create(testTemplate)
        persistenceController.create(testPlan)
        persistenceController.create(mondayTemplate)
        
        viewModel.loadAvailablePlans()
        viewModel.handleIntent(.selectPlan(testPlan.id))
        
        // When: Selecting Tuesday (which is not available in the plan)
        viewModel.handleIntent(.selectDay(.tuesday))
        
        // Then: Should be marked as rest day
        XCTAssertTrue(viewModel.isRestDay, "Tuesday should be marked as rest day")
        XCTAssertNil(viewModel.selectedDay, "No day template should be selected for rest day")
    }
    
    func testDaySelection_WithoutPlan_SetsError() {
        // Given: A LoggingViewModel without an active plan
        // (viewModel starts without active plan)
        
        // When: Trying to select a day without a plan
        viewModel.handleIntent(.selectDay(.monday))
        
        // Then: Error should be set
        XCTAssertNotNil(viewModel.error, "Error should be set when selecting day without plan")
        XCTAssertNil(viewModel.selectedDay, "No day should be selected")
        
        if let error = viewModel.error as? LoggingError {
            switch error {
            case .noPlanSelected:
                break // Expected error type
            default:
                XCTFail("Expected noPlanSelected error but got \(error)")
            }
        }
    }
    
    func testDaySelection_LoadsExercisesForDay() {
        // Given: A LoggingViewModel with a day template containing exercises
        let testTemplate = TestHelpers.createTestWorkoutTemplate(name: "Test Template")
        let testPlan = TestHelpers.createTestWorkoutPlan(customName: "Test Plan", template: testTemplate)
        let mondayTemplate = TestHelpers.createTestDayTemplate(weekday: .monday, workoutTemplate: testTemplate)
        
        let testExercise1 = TestHelpers.createTestExercise(name: "Exercise 1")
        let testExercise2 = TestHelpers.createTestExercise(name: "Exercise 2")
        let exerciseTemplate1 = TestHelpers.createTestExerciseTemplate(exercise: testExercise1, dayTemplate: mondayTemplate)
        let exerciseTemplate2 = TestHelpers.createTestExerciseTemplate(exercise: testExercise2, dayTemplate: mondayTemplate)
        
        persistenceController.create(testTemplate)
        persistenceController.create(testPlan)
        persistenceController.create(mondayTemplate)
        persistenceController.create(testExercise1)
        persistenceController.create(testExercise2)
        persistenceController.create(exerciseTemplate1)
        persistenceController.create(exerciseTemplate2)
        
        viewModel.loadAvailablePlans()
        viewModel.handleIntent(.selectPlan(testPlan.id))
        
        // When: Selecting Monday
        viewModel.handleIntent(.selectDay(.monday))
        
        // Then: Exercises should be loaded
        XCTAssertGreaterThan(viewModel.exercises.count, 0, "Exercises should be loaded for the day")
        XCTAssertTrue(viewModel.exercises.contains { $0.name == "Exercise 1" }, "Should contain Exercise 1")
        XCTAssertTrue(viewModel.exercises.contains { $0.name == "Exercise 2" }, "Should contain Exercise 2")
    }
    
    func testDaySelection_ClearsSessionState() {
        // Given: A LoggingViewModel with an active session
        viewModel.session = TestHelpers.createTestWorkoutSession(date: Date())
        viewModel.isWorkoutInProgress = true
        
        let testTemplate = TestHelpers.createTestWorkoutTemplate(name: "Test Template")
        let testPlan = TestHelpers.createTestWorkoutPlan(customName: "Test Plan", template: testTemplate)
        let mondayTemplate = TestHelpers.createTestDayTemplate(weekday: .monday, workoutTemplate: testTemplate)
        
        persistenceController.create(testTemplate)
        persistenceController.create(testPlan)
        persistenceController.create(mondayTemplate)
        
        viewModel.loadAvailablePlans()
        viewModel.handleIntent(.selectPlan(testPlan.id))
        
        // When: Selecting a day
        viewModel.handleIntent(.selectDay(.monday))
        
        // Then: Session state should be cleared
        XCTAssertNil(viewModel.session, "Session should be cleared when selecting new day")
        XCTAssertFalse(viewModel.isWorkoutInProgress, "Workout should not be in progress")
    }
    
    // MARK: - Exercise Logging Tests
    
    func testStartSession_ValidDay_CreatesSession() {
        // Given: A LoggingViewModel with a selected day
        let testTemplate = TestHelpers.createTestWorkoutTemplate(name: "Test Template")
        let testPlan = TestHelpers.createTestWorkoutPlan(customName: "Test Plan", template: testTemplate)
        let mondayTemplate = TestHelpers.createTestDayTemplate(weekday: .monday, workoutTemplate: testTemplate)
        let testExercise = TestHelpers.createTestExercise(name: "Test Exercise")
        let exerciseTemplate = TestHelpers.createTestExerciseTemplate(exercise: testExercise, dayTemplate: mondayTemplate)
        
        persistenceController.create(testTemplate)
        persistenceController.create(testPlan)
        persistenceController.create(mondayTemplate)
        persistenceController.create(testExercise)
        persistenceController.create(exerciseTemplate)
        
        viewModel.loadAvailablePlans()
        viewModel.handleIntent(.selectPlan(testPlan.id))
        viewModel.handleIntent(.selectDay(.monday))
        
        // When: Starting a workout session
        viewModel.handleIntent(.startSession)
        
        // Then: Session should be created
        XCTAssertNotNil(viewModel.session, "Workout session should be created")
        XCTAssertTrue(viewModel.isWorkoutInProgress, "Workout should be in progress")
        XCTAssertEqual(viewModel.currentExerciseIndex, 0, "Should start with first exercise")
        XCTAssertNil(viewModel.error, "No error should occur when starting session")
    }
    
    func testStartSession_WithoutSelectedDay_SetsError() {
        // Given: A LoggingViewModel without a selected day
        // (viewModel starts without selected day)
        
        // When: Trying to start a session without a selected day
        viewModel.handleIntent(.startSession)
        
        // Then: Error should be set and no session created
        XCTAssertNil(viewModel.session, "No session should be created")
        XCTAssertFalse(viewModel.isWorkoutInProgress, "Workout should not be in progress")
        XCTAssertNotNil(viewModel.error, "Error should be set")
        
        if let error = viewModel.error as? LoggingError {
            switch error {
            case .noDaySelected:
                break // Expected error type
            default:
                XCTFail("Expected noDaySelected error but got \(error)")
            }
        }
    }
    
    func testAddSet_ValidExercise_AddsSet() {
        // Given: A LoggingViewModel with an active session
        setupActiveSession()
        
        guard let firstExercise = viewModel.exercises.first else {
            XCTFail("Should have at least one exercise")
            return
        }
        
        let initialSetCount = firstExercise.sets.count
        
        // When: Adding a set to the first exercise
        viewModel.handleIntent(.addSet(exerciseID: firstExercise.id))
        
        // Then: Set should be added
        let updatedExercise = viewModel.exercises.first { $0.id == firstExercise.id }
        XCTAssertNotNil(updatedExercise, "Exercise should still exist")
        XCTAssertEqual(updatedExercise?.sets.count, initialSetCount + 1, "Set count should increase by 1")
        XCTAssertNil(viewModel.error, "No error should occur when adding set")
    }
    
    func testEditSet_ValidParameters_UpdatesSet() {
        // Given: A LoggingViewModel with an active session
        setupActiveSession()
        
        guard let firstExercise = viewModel.exercises.first else {
            XCTFail("Should have at least one exercise")
            return
        }
        
        let newReps = 12
        let newWeight = 100.0
        
        // When: Editing the first set
        viewModel.handleIntent(.editSet(exerciseID: firstExercise.id, setIndex: 0, reps: newReps, weight: newWeight))
        
        // Then: Set should be updated
        let updatedExercise = viewModel.exercises.first { $0.id == firstExercise.id }
        XCTAssertNotNil(updatedExercise, "Exercise should still exist")
        
        if let firstSet = updatedExercise?.sets.first {
            XCTAssertEqual(firstSet.reps, newReps, "Reps should be updated")
            XCTAssertEqual(firstSet.weight, newWeight, "Weight should be updated")
        } else {
            XCTFail("First set should exist")
        }
        
        XCTAssertNil(viewModel.error, "No error should occur when editing set")
    }
    
    func testEditSet_InvalidSetIndex_SetsError() {
        // Given: A LoggingViewModel with an active session
        setupActiveSession()
        
        guard let firstExercise = viewModel.exercises.first else {
            XCTFail("Should have at least one exercise")
            return
        }
        
        // When: Trying to edit a set with invalid index
        viewModel.handleIntent(.editSet(exerciseID: firstExercise.id, setIndex: 999, reps: 10, weight: 100))
        
        // Then: Error should be set
        XCTAssertNotNil(viewModel.error, "Error should be set for invalid set index")
        
        if let error = viewModel.error as? LoggingError {
            switch error {
            case .invalidSetIndex:
                break // Expected error type
            default:
                XCTFail("Expected invalidSetIndex error but got \(error)")
            }
        }
    }
    
    func testEditSet_InvalidExerciseID_SetsError() {
        // Given: A LoggingViewModel with an active session
        setupActiveSession()
        
        let invalidExerciseID = UUID()
        
        // When: Trying to edit a set for non-existent exercise
        viewModel.handleIntent(.editSet(exerciseID: invalidExerciseID, setIndex: 0, reps: 10, weight: 100))
        
        // Then: Error should be set
        XCTAssertNotNil(viewModel.error, "Error should be set for invalid exercise ID")
        
        if let error = viewModel.error as? LoggingError {
            switch error {
            case .exerciseNotFound:
                break // Expected error type
            default:
                XCTFail("Expected exerciseNotFound error but got \(error)")
            }
        }
    }
    
    func testToggleSetCompletion_ValidSet_TogglesCompletion() {
        // Given: A LoggingViewModel with an active session
        setupActiveSession()
        
        guard let firstExercise = viewModel.exercises.first else {
            XCTFail("Should have at least one exercise")
            return
        }
        
        let initialCompletionState = firstExercise.sets.first?.isCompleted ?? false
        
        // When: Toggling set completion
        viewModel.handleIntent(.toggleSetCompletion(exerciseID: firstExercise.id, setIndex: 0))
        
        // Then: Completion state should be toggled
        let updatedExercise = viewModel.exercises.first { $0.id == firstExercise.id }
        let newCompletionState = updatedExercise?.sets.first?.isCompleted ?? false
        
        XCTAssertNotEqual(initialCompletionState, newCompletionState, "Completion state should be toggled")
        XCTAssertNil(viewModel.error, "No error should occur when toggling set completion")
    }
    
    func testFinishSession_ValidSession_CompletesSession() {
        // Given: A LoggingViewModel with an active session
        setupActiveSession()
        
        // Mark some exercises as complete to enable finishing
        if let firstExercise = viewModel.exercises.first {
            viewModel.handleIntent(.markExerciseComplete(exerciseID: firstExercise.id))
        }
        
        // When: Finishing the session
        viewModel.handleIntent(.finishSession)
        
        // Then: Session should be completed
        XCTAssertFalse(viewModel.isWorkoutInProgress, "Workout should not be in progress after finishing")
        XCTAssertNil(viewModel.error, "No error should occur when finishing session")
    }
    
    func testCancelSession_ClearsSessionState() {
        // Given: A LoggingViewModel with an active session
        setupActiveSession()
        
        XCTAssertTrue(viewModel.isWorkoutInProgress, "Workout should be in progress initially")
        
        // When: Cancelling the session
        viewModel.handleIntent(.cancelSession)
        
        // Then: Session state should be cleared
        XCTAssertFalse(viewModel.isWorkoutInProgress, "Workout should not be in progress after cancelling")
        XCTAssertNil(viewModel.session, "Session should be cleared")
        XCTAssertEqual(viewModel.currentExerciseIndex, 0, "Exercise index should be reset")
    }
    
    // MARK: - Helper Methods
    
    private func setupActiveSession() {
        let testTemplate = TestHelpers.createTestWorkoutTemplate(name: "Test Template")
        let testPlan = TestHelpers.createTestWorkoutPlan(customName: "Test Plan", template: testTemplate)
        let mondayTemplate = TestHelpers.createTestDayTemplate(weekday: .monday, workoutTemplate: testTemplate)
        let testExercise = TestHelpers.createTestExercise(name: "Test Exercise")
        let exerciseTemplate = TestHelpers.createTestExerciseTemplate(exercise: testExercise, dayTemplate: mondayTemplate)
        
        persistenceController.create(testTemplate)
        persistenceController.create(testPlan)
        persistenceController.create(mondayTemplate)
        persistenceController.create(testExercise)
        persistenceController.create(exerciseTemplate)
        
        viewModel.loadAvailablePlans()
        viewModel.handleIntent(.selectPlan(testPlan.id))
        viewModel.handleIntent(.selectDay(.monday))
        viewModel.handleIntent(.startSession)
    }
}

// MARK: - Mock Timer Factory

class MockTimerFactory: TimerFactory {
    var createdTimers: [MockTimer] = []
    
    func createTimer(interval: TimeInterval, repeats: Bool, block: @escaping (Timer) -> Void) -> Timer {
        let mockTimer = MockTimer(interval: interval, repeats: repeats, block: block)
        createdTimers.append(mockTimer)
        return mockTimer
    }
}

class MockTimer: Timer {
    let mockInterval: TimeInterval
    let mockRepeats: Bool
    let mockBlock: (Timer) -> Void
    private var _isValid = true
    
    init(interval: TimeInterval, repeats: Bool, block: @escaping (Timer) -> Void) {
        self.mockInterval = interval
        self.mockRepeats = repeats
        self.mockBlock = block
        super.init()
    }
    
    override func invalidate() {
        _isValid = false
        super.invalidate()
    }
    
    override var isValid: Bool {
        return _isValid
    }
    
    func mockFire() {
        if _isValid {
            mockBlock(self)
            if !mockRepeats {
                invalidate()
            }
        }
    }
}