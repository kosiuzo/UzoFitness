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
        XCTAssertEqual(viewModel.activePlan?.id, workoutPlan.id)
        XCTAssertNotNil(viewModel.activePlan)
        
        print("✅ [LoggingViewModelTests.testSelectPlan_ValidPlan_SetsActivePlan] Passed")
    }
    
    func testSelectPlan_InvalidPlanID_SetsError() async throws {
        // Given
        let invalidID = UUID()
        
        // When
        viewModel.handleIntent(.selectPlan(invalidID))
        
        // Then
        XCTAssertNotNil(viewModel.error)
        
        print("✅ [LoggingViewModelTests.testSelectPlan_InvalidPlanID_SetsError] Passed")
    }
    
    // MARK: - Day Selection Tests
    
    func testSelectDay_ValidDay_SetsSelectedDay() async throws {
        // Given
        let workoutTemplate = WorkoutTemplate(name: "Test Template")
        let dayTemplate = DayTemplate(weekday: .monday, workoutTemplate: workoutTemplate)
        let workoutPlan = WorkoutPlan(customName: "Test Plan", template: workoutTemplate)
        
        modelContext.insert(workoutTemplate)
        modelContext.insert(dayTemplate)
        modelContext.insert(workoutPlan)
        workoutTemplate.dayTemplates.append(dayTemplate)
        try modelContext.save()
        
        viewModel.handleIntent(.selectPlan(workoutPlan.id))
        
        // When
        viewModel.handleIntent(.selectDay(.monday))
        
        // Then
        XCTAssertEqual(viewModel.selectedDay?.weekday, .monday)
        XCTAssertFalse(viewModel.isRestDay)
        
        print("✅ [LoggingViewModelTests.testSelectDay_ValidDay_SetsSelectedDay] Passed")
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
}

// MARK: - Mock Timer Factory

class MockTimerFactory: TimerFactory {
    var timerCreated = false
    
    func createTimer(interval: TimeInterval, repeats: Bool, block: @escaping (Timer) -> Void) -> Timer {
        timerCreated = true
        return Timer.scheduledTimer(withTimeInterval: interval, repeats: repeats, block: block)
    }
} 