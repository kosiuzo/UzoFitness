import Foundation
import SwiftData
import UzoFitnessCore
@testable import UzoFitness

/// Test helper utilities for UzoFitness tests
/// Provides common functionality used across multiple test files
@MainActor
public class TestHelpers {
    
    // MARK: - Async/Await Support
    
    /// Wait for a specified duration (useful for async operations)
    public static func wait(seconds: TimeInterval) async {
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
    
    /// Wait for a condition to become true with timeout
    public static func waitForCondition(
        timeout: TimeInterval = 5.0,
        condition: @escaping () -> Bool
    ) async -> Bool {
        let startTime = Date()
        
        while Date().timeIntervalSince(startTime) < timeout {
            if condition() {
                return true
            }
            await wait(seconds: 0.1)
        }
        
        return false
    }
    
    // MARK: - Test Data Creation
    
    /// Create a test exercise with default values
    public static func createTestExercise(
        name: String = "Test Exercise",
        category: ExerciseCategory = .strength,
        instructions: String = "Test instructions"
    ) -> Exercise {
        return Exercise(name: name, category: category, instructions: instructions)
    }
    
    /// Create a test workout template with default values
    public static func createTestWorkoutTemplate(
        name: String = "Test Template",
        summary: String = "Test summary"
    ) -> WorkoutTemplate {
        return WorkoutTemplate(name: name, summary: summary)
    }
    
    /// Create a test workout session with default values
    public static func createTestWorkoutSession(
        date: Date = Date(),
        title: String = "Test Session",
        plan: WorkoutPlan? = nil
    ) -> WorkoutSession {
        return WorkoutSession(date: date, title: title, plan: plan)
    }
    
    /// Create a test session exercise with default values
    public static func createTestSessionExercise(
        exercise: Exercise,
        plannedSets: Int = 3,
        plannedReps: Int = 10,
        plannedWeight: Double? = nil,
        position: Double = 1.0
    ) -> SessionExercise {
        return SessionExercise(
            exercise: exercise,
            plannedSets: plannedSets,
            plannedReps: plannedReps,
            plannedWeight: plannedWeight,
            position: position
        )
    }
    
    /// Create a test completed set with default values
    public static func createTestCompletedSet(
        reps: Int = 10,
        weight: Double = 0,
        sessionExercise: SessionExercise? = nil
    ) -> CompletedSet {
        let set = CompletedSet(reps: reps, weight: weight)
        set.sessionExercise = sessionExercise
        return set
    }
    
    /// Create a test progress photo with default values
    public static func createTestProgressPhoto(
        date: Date = Date(),
        angle: PhotoAngle = .front,
        assetIdentifier: String = "test-asset-identifier",
        notes: String = "Test photo"
    ) -> ProgressPhoto {
        return ProgressPhoto(
            date: date,
            angle: angle,
            assetIdentifier: assetIdentifier,
            notes: notes
        )
    }
    
    /// Create a test exercise template with default values
    public static func createTestExerciseTemplate(
        exercise: Exercise,
        setCount: Int = 3,
        reps: Int = 10,
        weight: Double? = nil,
        position: Double = 1.0,
        dayTemplate: DayTemplate? = nil
    ) -> ExerciseTemplate {
        let template = ExerciseTemplate(
            exercise: exercise,
            setCount: setCount,
            reps: reps,
            weight: weight,
            position: position
        )
        template.dayTemplate = dayTemplate
        return template
    }
    
    /// Create a test day template with default values
    public static func createTestDayTemplate(
        weekday: Weekday = .monday,
        notes: String = "Test day",
        workoutTemplate: WorkoutTemplate? = nil
    ) -> DayTemplate {
        let dayTemplate = DayTemplate(weekday: weekday, notes: notes)
        dayTemplate.workoutTemplate = workoutTemplate
        return dayTemplate
    }
    
    /// Create a test workout plan with default values
    public static func createTestWorkoutPlan(
        customName: String = "Test Plan",
        template: WorkoutTemplate
    ) -> WorkoutPlan {
        return WorkoutPlan(customName: customName, template: template)
    }
    
    /// Create a test performed exercise with default values
    public static func createTestPerformedExercise(
        exercise: Exercise,
        reps: Int = 10,
        weight: Double = 0,
        performedAt: Date = Date()
    ) -> PerformedExercise {
        return PerformedExercise(
            performedAt: performedAt,
            reps: reps,
            weight: weight,
            exercise: exercise
        )
    }
    
    // MARK: - Mock Factory Methods
    
    /// Create a mock persistence controller for testing
    public static func createMockPersistenceController() -> InMemoryPersistenceController {
        return InMemoryPersistenceController()
    }
    
    /// Create a complete test workout setup
    public static func createCompleteTestWorkout(
        persistenceController: InMemoryPersistenceController
    ) -> (Exercise, WorkoutTemplate, DayTemplate, ExerciseTemplate, WorkoutPlan, WorkoutSession, SessionExercise, CompletedSet) {
        
        // Create exercise
        let exercise = createTestExercise(name: "Bench Press", category: .strength)
        persistenceController.create(exercise)
        
        // Create workout template
        let template = createTestWorkoutTemplate(name: "Upper Body", summary: "Upper body workout")
        persistenceController.create(template)
        
        // Create day template
        let dayTemplate = createTestDayTemplate(weekday: .monday, workoutTemplate: template)
        persistenceController.create(dayTemplate)
        
        // Create exercise template
        let exerciseTemplate = createTestExerciseTemplate(
            exercise: exercise,
            setCount: 3,
            reps: 8,
            weight: 135,
            position: 1.0,
            dayTemplate: dayTemplate
        )
        persistenceController.create(exerciseTemplate)
        
        // Create workout plan
        let plan = createTestWorkoutPlan(customName: "My Plan", template: template)
        persistenceController.create(plan)
        
        // Create workout session
        let session = createTestWorkoutSession(title: "Morning Workout", plan: plan)
        persistenceController.create(session)
        
        // Create session exercise
        let sessionExercise = createTestSessionExercise(
            exercise: exercise,
            plannedSets: 3,
            plannedReps: 8,
            plannedWeight: 135,
            position: 1.0
        )
        sessionExercise.session = session
        persistenceController.create(sessionExercise)
        
        // Create completed set
        let completedSet = createTestCompletedSet(
            reps: 8,
            weight: 135,
            sessionExercise: sessionExercise
        )
        persistenceController.create(completedSet)
        
        return (exercise, template, dayTemplate, exerciseTemplate, plan, session, sessionExercise, completedSet)
    }
    
    // MARK: - Validation Helpers
    
    /// Validate that a model has been properly persisted
    public static func validateModelPersisted<T: PersistentModel & Identified>(
        _ model: T,
        in persistenceController: InMemoryPersistenceController
    ) -> Bool {
        let fetched = persistenceController.fetch(T.self)
        return fetched.contains { $0.id == model.id }
    }
    
    /// Validate that a model has been properly deleted
    public static func validateModelDeleted<T: PersistentModel & Identified>(
        _ model: T,
        in persistenceController: InMemoryPersistenceController
    ) -> Bool {
        let fetched = persistenceController.fetch(T.self)
        return !fetched.contains { $0.id == model.id }
    }
    
    /// Validate that relationships are properly established
    public static func validateRelationship<T: PersistentModel & Identified, U: PersistentModel & Identified>(
        parent: T,
        child: U,
        relationshipName: String,
        in persistenceController: InMemoryPersistenceController
    ) -> Bool {
        // This is a basic validation - specific relationship validation would need to be implemented per model
        let parentFetched = persistenceController.fetch(T.self).contains { $0.id == parent.id }
        let childFetched = persistenceController.fetch(U.self).contains { $0.id == child.id }
        return parentFetched && childFetched
    }
    
    // MARK: - Error Simulation
    
    /// Simulate a database error by corrupting the context
    public static func simulateDatabaseError(in persistenceController: InMemoryPersistenceController) {
        // This would need to be implemented based on specific error scenarios
        // For now, we'll just log that we're simulating an error
        print("🔄 [TestHelpers.simulateDatabaseError] Simulating database error")
    }
    
    // MARK: - Performance Testing
    
    /// Create a large dataset for performance testing
    public static func createLargeDataset(
        exerciseCount: Int = 100,
        sessionCount: Int = 50,
        in persistenceController: InMemoryPersistenceController
    ) {
        print("🔄 [TestHelpers.createLargeDataset] Creating large dataset with \(exerciseCount) exercises and \(sessionCount) sessions")
        
        // Create exercises
        for i in 1...exerciseCount {
            let exercise = createTestExercise(
                name: "Exercise \(i)",
                category: i % 2 == 0 ? .strength : .cardio
            )
            persistenceController.create(exercise)
        }
        
        // Create workout sessions
        let exercises = persistenceController.fetch(Exercise.self)
        for i in 1...sessionCount {
            let session = createTestWorkoutSession(
                date: Date().addingTimeInterval(-Double(i * 86400)), // Each session one day apart
                title: "Session \(i)"
            )
            persistenceController.create(session)
            
            // Add some exercises to each session
            let sessionExercises = Array(exercises.prefix(3))
            for (index, exercise) in sessionExercises.enumerated() {
                let sessionExercise = createTestSessionExercise(
                    exercise: exercise,
                    plannedSets: 3,
                    plannedReps: 10,
                    position: Double(index + 1)
                )
                sessionExercise.session = session
                persistenceController.create(sessionExercise)
                
                // Add completed sets
                for setIndex in 1...3 {
                    let completedSet = createTestCompletedSet(
                        reps: 10,
                        weight: Double(setIndex * 10),
                        sessionExercise: sessionExercise
                    )
                    persistenceController.create(completedSet)
                }
            }
        }
        
        print("✅ [TestHelpers.createLargeDataset] Large dataset creation completed")
    }
    
    // MARK: - Test Data Cleanup
    
    /// Clean up all test data from a persistence controller
    public static func cleanupTestData(in persistenceController: InMemoryPersistenceController) {
        print("🔄 [TestHelpers.cleanupTestData] Cleaning up test data")
        persistenceController.cleanupTestData()
        print("✅ [TestHelpers.cleanupTestData] Test data cleanup completed")
    }
} 