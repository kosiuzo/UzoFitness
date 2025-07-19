import Foundation
import SwiftData
import UzoFitnessCore
@testable import UzoFitness

/// In-memory persistence controller for testing purposes
/// Provides isolated data storage that doesn't persist between test runs
@MainActor
class InMemoryPersistenceController: PersistenceController {
    
    // MARK: - Test-specific properties
    private var testDataInserted = false
    
    // MARK: - Initialization
    override init(inMemory: Bool = true) {
        // Force in-memory for testing
        super.init(inMemory: true)
        print("🔄 [InMemoryPersistenceController.init] Created in-memory container for testing")
    }
    
    // MARK: - Test Setup and Teardown
    
    /// Set up test data for a specific test
    func setupTestData() {
        guard !testDataInserted else {
            print("📊 [InMemoryPersistenceController.setupTestData] Test data already inserted, skipping")
            return
        }
        
        print("🔄 [InMemoryPersistenceController.setupTestData] Setting up test data")
        
        // Create basic test exercises
        let exercises = createTestExercises()
        exercises.forEach { create($0) }
        
        // Create basic test workout template
        let template = createTestWorkoutTemplate()
        create(template)
        
        // Create basic test workout plan
        let plan = createTestWorkoutPlan(template: template)
        create(plan)
        
        testDataInserted = true
        print("✅ [InMemoryPersistenceController.setupTestData] Test data setup completed")
    }
    
    /// Clean up all test data
    func cleanupTestData() {
        print("🔄 [InMemoryPersistenceController.cleanupTestData] Cleaning up test data")
        deleteAllData()
        testDataInserted = false
        print("✅ [InMemoryPersistenceController.cleanupTestData] Test data cleanup completed")
    }
    
    /// Reset the test environment
    func resetTestEnvironment() {
        print("🔄 [InMemoryPersistenceController.resetTestEnvironment] Resetting test environment")
        cleanupTestData()
        setupTestData()
        print("✅ [InMemoryPersistenceController.resetTestEnvironment] Test environment reset completed")
    }
    
    // MARK: - Test Data Factories
    
    private func createTestExercises() -> [Exercise] {
        return [
            Exercise(name: "Push-up", category: .strength, instructions: "Standard push-up exercise"),
            Exercise(name: "Squat", category: .strength, instructions: "Bodyweight squat"),
            Exercise(name: "Plank", category: .strength, instructions: "Hold plank position"),
            Exercise(name: "Pull-up", category: .strength, instructions: "Pull-up exercise"),
            Exercise(name: "Bench Press", category: .strength, instructions: "Barbell bench press")
        ]
    }
    
    private func createTestWorkoutTemplate() -> WorkoutTemplate {
        let template = WorkoutTemplate(name: "Test Workout", summary: "Test workout template")
        
        // Create day template
        let dayTemplate = DayTemplate(weekday: .monday, notes: "Test day")
        dayTemplate.workoutTemplate = template
        
        // Create exercise templates
        let exercises = fetch(Exercise.self)
        if let pushup = exercises.first(where: { $0.name == "Push-up" }) {
            let pushupTemplate = ExerciseTemplate(exercise: pushup, setCount: 3, reps: 10, position: 1.0)
            pushupTemplate.dayTemplate = dayTemplate
        }
        
        if let plank = exercises.first(where: { $0.name == "Plank" }) {
            let plankTemplate = ExerciseTemplate(exercise: plank, setCount: 3, reps: 1, weight: nil, position: 2.0)
            plankTemplate.dayTemplate = dayTemplate
        }
        
        return template
    }
    
    private func createTestWorkoutPlan(template: WorkoutTemplate) -> WorkoutPlan {
        return WorkoutPlan(customName: "Test Plan", template: template)
    }
    
    // MARK: - Test Helper Methods
    
    /// Verify that all model types can be inserted and fetched
    func verifyAllModelTypes() -> Bool {
        print("🔄 [InMemoryPersistenceController.verifyAllModelTypes] Verifying all model types")
        
        let testResults = [
            testExerciseModel(),
            testWorkoutTemplateModel(),
            testWorkoutSessionModel(),
            testSessionExerciseModel(),
            testCompletedSetModel(),
            testProgressPhotoModel(),
            testExerciseTemplateModel(),
            testDayTemplateModel(),
            testWorkoutPlanModel(),
            testPerformedExerciseModel()
        ]
        
        let allPassed = testResults.allSatisfy { $0 }
        print("📊 [InMemoryPersistenceController.verifyAllModelTypes] All model types verified: \(allPassed)")
        return allPassed
    }
    
    // MARK: - Individual Model Tests
    
    private func testExerciseModel() -> Bool {
        let exercise = Exercise(name: "Test Exercise", category: .strength, instructions: "Test")
        create(exercise)
        let fetched = fetch(Exercise.self)
        let success = fetched.contains { $0.id == exercise.id }
        delete(exercise)
        return success
    }
    
    private func testWorkoutTemplateModel() -> Bool {
        let template = WorkoutTemplate(name: "Test Template", summary: "Test")
        create(template)
        let fetched = fetch(WorkoutTemplate.self)
        let success = fetched.contains { $0.id == template.id }
        delete(template)
        return success
    }
    
    private func testWorkoutSessionModel() -> Bool {
        let session = WorkoutSession(date: Date(), title: "Test Session", plan: nil)
        create(session)
        let fetched = fetch(WorkoutSession.self)
        let success = fetched.contains { $0.id == session.id }
        delete(session)
        return success
    }
    
    private func testSessionExerciseModel() -> Bool {
        let exercise = Exercise(name: "Test Exercise", category: .strength, instructions: "Test")
        create(exercise)
        
        let sessionExercise = SessionExercise(
            exercise: exercise,
            plannedSets: 3,
            plannedReps: 10,
            plannedWeight: nil,
            position: 1.0
        )
        create(sessionExercise)
        
        let fetched = fetch(SessionExercise.self)
        let success = fetched.contains { $0.id == sessionExercise.id }
        
        delete(sessionExercise)
        delete(exercise)
        return success
    }
    
    private func testCompletedSetModel() -> Bool {
        let exercise = Exercise(name: "Test Exercise", category: .strength, instructions: "Test")
        create(exercise)
        
        let sessionExercise = SessionExercise(
            exercise: exercise,
            plannedSets: 3,
            plannedReps: 10,
            plannedWeight: nil,
            position: 1.0
        )
        create(sessionExercise)
        
        let completedSet = CompletedSet(reps: 10, weight: 0)
        completedSet.sessionExercise = sessionExercise
        create(completedSet)
        
        let fetched = fetch(CompletedSet.self)
        let success = fetched.contains { $0.id == completedSet.id }
        
        delete(completedSet)
        delete(sessionExercise)
        delete(exercise)
        return success
    }
    
    private func testProgressPhotoModel() -> Bool {
        let photo = ProgressPhoto(
            date: Date(),
            angle: .front,
            assetIdentifier: "test-progress-photo-\(UUID().uuidString)",
            notes: "Test photo"
        )
        create(photo)
        let fetched = fetch(ProgressPhoto.self)
        let success = fetched.contains { $0.id == photo.id }
        delete(photo)
        return success
    }
    
    private func testExerciseTemplateModel() -> Bool {
        let exercise = Exercise(name: "Test Exercise", category: .strength, instructions: "Test")
        create(exercise)
        
        let dayTemplate = DayTemplate(weekday: .monday, notes: "Test day")
        create(dayTemplate)
        
        let exerciseTemplate = ExerciseTemplate(exercise: exercise, setCount: 3, reps: 10, position: 1.0)
        exerciseTemplate.dayTemplate = dayTemplate
        create(exerciseTemplate)
        
        let fetched = fetch(ExerciseTemplate.self)
        let success = fetched.contains { $0.id == exerciseTemplate.id }
        
        delete(exerciseTemplate)
        delete(dayTemplate)
        delete(exercise)
        return success
    }
    
    private func testDayTemplateModel() -> Bool {
        let dayTemplate = DayTemplate(weekday: .monday, notes: "Test day")
        create(dayTemplate)
        let fetched = fetch(DayTemplate.self)
        let success = fetched.contains { $0.id == dayTemplate.id }
        delete(dayTemplate)
        return success
    }
    
    private func testWorkoutPlanModel() -> Bool {
        let template = WorkoutTemplate(name: "Test Template", summary: "Test")
        create(template)
        
        let plan = WorkoutPlan(customName: "Test Plan", template: template)
        create(plan)
        
        let fetched = fetch(WorkoutPlan.self)
        let success = fetched.contains { $0.id == plan.id }
        
        delete(plan)
        delete(template)
        return success
    }
    
    private func testPerformedExerciseModel() -> Bool {
        let exercise = Exercise(name: "Test Exercise", category: .strength, instructions: "Test")
        create(exercise)
        
        let performedExercise = PerformedExercise(
            performedAt: Date(),
            reps: 10,
            weight: 0,
            exercise: exercise
        )
        create(performedExercise)
        
        let fetched = fetch(PerformedExercise.self)
        let success = fetched.contains { $0.id == performedExercise.id }
        
        delete(performedExercise)
        delete(exercise)
        return success
    }
} 