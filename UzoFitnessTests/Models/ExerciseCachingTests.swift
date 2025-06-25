import XCTest
import SwiftData
@testable import UzoFitness

final class ExerciseCachingTests: XCTestCase {
    var modelContainer: ModelContainer!
    var context: ModelContext!
    
    override func setUpWithError() throws {
        print("🔄 [ExerciseCachingTests.setUpWithError] Setting up test environment")
        
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(
            for: Exercise.self, 
                 SessionExercise.self, 
                 CompletedSet.self, 
                 WorkoutSession.self,
            configurations: config
        )
        context = ModelContext(modelContainer)
    }
    
    override func tearDownWithError() throws {
        print("🔄 [ExerciseCachingTests.tearDownWithError] Cleaning up test environment")
        modelContainer = nil
        context = nil
    }
    
    // MARK: - Exercise Caching Tests
    
    func testExerciseCacheInitialState() throws {
        print("🧪 [ExerciseCachingTests.testExerciseCacheInitialState] Testing initial cache state")
        
        // Given
        let exercise = Exercise(
            name: "Bench Press",
            category: .strength,
            instructions: "Press the barbell"
        )
        
        // When
        context.insert(exercise)
        
        // Then
        XCTAssertNil(exercise.lastUsedWeight, "Initial weight should be nil")
        XCTAssertNil(exercise.lastUsedReps, "Initial reps should be nil")
        XCTAssertNil(exercise.lastTotalVolume, "Initial volume should be nil")
        XCTAssertNil(exercise.lastUsedDate, "Initial date should be nil")
        
        let suggestedValues = exercise.suggestedStartingValues
        XCTAssertNil(suggestedValues.weight, "Suggested weight should be nil initially")
        XCTAssertNil(suggestedValues.reps, "Suggested reps should be nil initially")
        XCTAssertNil(suggestedValues.totalVolume, "Suggested volume should be nil initially")
        
        print("✅ [ExerciseCachingTests.testExerciseCacheInitialState] Test passed")
    }
    
    func testExerciseCacheManualUpdate() throws {
        print("🧪 [ExerciseCachingTests.testExerciseCacheManualUpdate] Testing manual cache update")
        
        // Given
        let exercise = Exercise(
            name: "Bench Press",
            category: .strength,
            instructions: "Press the barbell"
        )
        context.insert(exercise)
        
        // When
        exercise.lastUsedWeight = 135.0
        exercise.lastUsedReps = 8
        exercise.lastTotalVolume = 1080.0 // 8 * 135
        exercise.lastUsedDate = Date()
        
        // Then
        let suggestedValues = exercise.suggestedStartingValues
        XCTAssertEqual(suggestedValues.weight, 135.0, "Suggested weight should match cached value")
        XCTAssertEqual(suggestedValues.reps, 8, "Suggested reps should match cached value")
        XCTAssertEqual(suggestedValues.totalVolume, 1080.0, "Suggested volume should match cached value")
        
        print("✅ [ExerciseCachingTests.testExerciseCacheManualUpdate] Test passed")
    }
    
    // MARK: - SessionExercise Auto-Population Tests
    
    func testSessionExerciseAutoPopulationWithCache() throws {
        print("🧪 [ExerciseCachingTests.testSessionExerciseAutoPopulationWithCache] Testing auto-population with cached data")
        
        // Given
        let exercise = Exercise(
            name: "Bench Press",
            category: .strength,
            instructions: "Press the barbell"
        )
        exercise.lastUsedWeight = 135.0
        exercise.lastUsedReps = 8
        exercise.lastTotalVolume = 1080.0
        exercise.lastUsedDate = Date()
        
        context.insert(exercise)
        
        // When
        let sessionExercise = SessionExercise(
            exercise: exercise,
            plannedSets: 3,
            position: 1.0,
            autoPopulateFromLastSession: true
        )
        context.insert(sessionExercise)
        
        // Then
        XCTAssertEqual(sessionExercise.plannedReps, 8, "Planned reps should be auto-populated from cache")
        XCTAssertEqual(sessionExercise.plannedWeight, 135.0, "Planned weight should be auto-populated from cache")
        XCTAssertEqual(sessionExercise.previousTotalVolume, 1080.0, "Previous volume should be set from cache")
        XCTAssertEqual(sessionExercise.previousSessionDate, exercise.lastUsedDate, "Previous date should match exercise date")
        
        print("✅ [ExerciseCachingTests.testSessionExerciseAutoPopulationWithCache] Test passed")
    }
    
    func testSessionExerciseAutoPopulationWithoutCache() throws {
        print("🧪 [ExerciseCachingTests.testSessionExerciseAutoPopulationWithoutCache] Testing auto-population without cached data")
        
        // Given
        let exercise = Exercise(
            name: "New Exercise",
            category: .strength,
            instructions: "New exercise with no history"
        )
        context.insert(exercise)
        
        // When
        let sessionExercise = SessionExercise(
            exercise: exercise,
            plannedSets: 3,
            position: 1.0,
            autoPopulateFromLastSession: true
        )
        context.insert(sessionExercise)
        
        // Then
        XCTAssertEqual(sessionExercise.plannedReps, 10, "Planned reps should default to 10 when no cache")
        XCTAssertNil(sessionExercise.plannedWeight, "Planned weight should be nil when no cache")
        XCTAssertNil(sessionExercise.previousTotalVolume, "Previous volume should be nil when no cache")
        XCTAssertNil(sessionExercise.previousSessionDate, "Previous date should be nil when no cache")
        
        print("✅ [ExerciseCachingTests.testSessionExerciseAutoPopulationWithoutCache] Test passed")
    }
    
    func testSessionExerciseManualOverride() throws {
        print("🧪 [ExerciseCachingTests.testSessionExerciseManualOverride] Testing manual override of auto-population")
        
        // Given
        let exercise = Exercise(
            name: "Bench Press",
            category: .strength,
            instructions: "Press the barbell"
        )
        exercise.lastUsedWeight = 135.0
        exercise.lastUsedReps = 8
        exercise.lastTotalVolume = 1080.0
        exercise.lastUsedDate = Date()
        
        context.insert(exercise)
        
        // When
        let sessionExercise = SessionExercise(
            exercise: exercise,
            plannedSets: 3,
            plannedReps: 12,
            plannedWeight: 115.0,
            position: 1.0,
            autoPopulateFromLastSession: true
        )
        context.insert(sessionExercise)
        
        // Then
        XCTAssertEqual(sessionExercise.plannedReps, 12, "Manual reps should override cache")
        XCTAssertEqual(sessionExercise.plannedWeight, 115.0, "Manual weight should override cache")
        XCTAssertEqual(sessionExercise.previousTotalVolume, 1080.0, "Previous volume should still be set from cache")
        
        print("✅ [ExerciseCachingTests.testSessionExerciseManualOverride] Test passed")
    }
    
    func testSessionExerciseWithoutAutoPopulation() throws {
        print("🧪 [ExerciseCachingTests.testSessionExerciseWithoutAutoPopulation] Testing disabled auto-population")
        
        // Given
        let exercise = Exercise(
            name: "Bench Press",
            category: .strength,
            instructions: "Press the barbell"
        )
        exercise.lastUsedWeight = 135.0
        exercise.lastUsedReps = 8
        exercise.lastTotalVolume = 1080.0
        exercise.lastUsedDate = Date()
        
        context.insert(exercise)
        
        // When
        let sessionExercise = SessionExercise(
            exercise: exercise,
            plannedSets: 3,
            plannedReps: 12,
            plannedWeight: 115.0,
            position: 1.0,
            autoPopulateFromLastSession: false
        )
        context.insert(sessionExercise)
        
        // Then
        XCTAssertEqual(sessionExercise.plannedReps, 12, "Manual reps should be used")
        XCTAssertEqual(sessionExercise.plannedWeight, 115.0, "Manual weight should be used")
        XCTAssertNil(sessionExercise.previousTotalVolume, "Previous volume should be nil when auto-population disabled")
        XCTAssertNil(sessionExercise.previousSessionDate, "Previous date should be nil when auto-population disabled")
        
        print("✅ [ExerciseCachingTests.testSessionExerciseWithoutAutoPopulation] Test passed")
    }
    
    // MARK: - Volume Comparison Tests
    
    func testVolumeChangeCalculation() throws {
        print("🧪 [ExerciseCachingTests.testVolumeChangeCalculation] Testing volume change calculation")
        
        // Given
        let exercise = Exercise(
            name: "Bench Press",
            category: .strength,
            instructions: "Press the barbell"
        )
        context.insert(exercise)
        
        let sessionExercise = SessionExercise(
            exercise: exercise,
            plannedSets: 3,
            plannedReps: 8,
            plannedWeight: 135.0,
            position: 1.0,
            autoPopulateFromLastSession: false
        )
        sessionExercise.previousTotalVolume = 1000.0 // Previous session volume
        context.insert(sessionExercise)
        
        // When - Complete some sets
        let set1 = CompletedSet(reps: 8, weight: 135.0, sessionExercise: sessionExercise)
        let set2 = CompletedSet(reps: 8, weight: 135.0, sessionExercise: sessionExercise)
        let set3 = CompletedSet(reps: 6, weight: 135.0, sessionExercise: sessionExercise)
        
        context.insert(set1)
        context.insert(set2)
        context.insert(set3)
        
        // Current volume: (8 + 8 + 6) * 135 = 2970
        let expectedCurrentVolume = 2970.0
        let expectedVolumeChange = expectedCurrentVolume - 1000.0 // 1970.0
        let expectedPercentageChange = (expectedVolumeChange / 1000.0) * 100 // 197.0%
        
        // Then
        XCTAssertEqual(sessionExercise.totalVolume, expectedCurrentVolume, accuracy: 0.01, "Current volume should be calculated correctly")
        XCTAssertEqual(sessionExercise.volumeChange ?? 0, expectedVolumeChange, accuracy: 0.01, "Volume change should be calculated correctly")
        XCTAssertEqual(sessionExercise.volumeChangePercentage ?? 0, expectedPercentageChange, accuracy: 0.01, "Volume change percentage should be calculated correctly")
        
        print("✅ [ExerciseCachingTests.testVolumeChangeCalculation] Test passed")
    }
    
    func testVolumeChangeWithNoPreviousData() throws {
        print("🧪 [ExerciseCachingTests.testVolumeChangeWithNoPreviousData] Testing volume change with no previous data")
        
        // Given
        let exercise = Exercise(
            name: "New Exercise",
            category: .strength,
            instructions: "New exercise"
        )
        context.insert(exercise)
        
        let sessionExercise = SessionExercise(
            exercise: exercise,
            plannedSets: 3,
            plannedReps: 8,
            plannedWeight: 135.0,
            position: 1.0,
            autoPopulateFromLastSession: false
        )
        context.insert(sessionExercise)
        
        // When - Complete some sets
        let set1 = CompletedSet(reps: 8, weight: 135.0, sessionExercise: sessionExercise)
        context.insert(set1)
        
        // Then
        XCTAssertNil(sessionExercise.volumeChange, "Volume change should be nil with no previous data")
        XCTAssertNil(sessionExercise.volumeChangePercentage, "Volume change percentage should be nil with no previous data")
        
        print("✅ [ExerciseCachingTests.testVolumeChangeWithNoPreviousData] Test passed")
    }
    
    // MARK: - Cache Update Tests
    
    func testExerciseCacheUpdateOnCompletion() throws {
        print("🧪 [ExerciseCachingTests.testExerciseCacheUpdateOnCompletion] Testing cache update on session completion")
        
        // Given
        let exercise = Exercise(
            name: "Bench Press",
            category: .strength,
            instructions: "Press the barbell"
        )
        context.insert(exercise)
        
        let workoutSession = WorkoutSession(
            date: Date(),
            title: "Test Workout"
        )
        context.insert(workoutSession)
        
        let sessionExercise = SessionExercise(
            exercise: exercise,
            plannedSets: 3,
            plannedReps: 8,
            plannedWeight: 135.0,
            position: 1.0,
            session: workoutSession,
            autoPopulateFromLastSession: false
        )
        context.insert(sessionExercise)
        
        // When - Complete sets and mark as completed
        let set1 = CompletedSet(reps: 8, weight: 135.0, sessionExercise: sessionExercise)
        let set2 = CompletedSet(reps: 8, weight: 140.0, sessionExercise: sessionExercise)
        let set3 = CompletedSet(reps: 6, weight: 145.0, sessionExercise: sessionExercise)
        
        context.insert(set1)
        context.insert(set2)
        context.insert(set3)
        
        sessionExercise.isCompleted = true
        sessionExercise.updateExerciseCacheOnCompletion()
        
        // Then
        XCTAssertEqual(exercise.lastUsedWeight, 145.0, "Last used weight should be from the final set")
        XCTAssertEqual(exercise.lastUsedReps, 6, "Last used reps should be from the final set")
        
        let expectedTotalVolume = (8 * 135.0) + (8 * 140.0) + (6 * 145.0) // 1080 + 1120 + 870 = 3070
        XCTAssertEqual(exercise.lastTotalVolume ?? 0, expectedTotalVolume, accuracy: 0.01, "Last total volume should be calculated correctly")
        XCTAssertEqual(exercise.lastUsedDate, workoutSession.date, "Last used date should match session date")
        
        print("✅ [ExerciseCachingTests.testExerciseCacheUpdateOnCompletion] Test passed")
    }
    
    func testExerciseCacheUpdateWithoutCompletion() throws {
        print("🧪 [ExerciseCachingTests.testExerciseCacheUpdateWithoutCompletion] Testing cache update without completion")
        
        // Given
        let exercise = Exercise(
            name: "Bench Press",
            category: .strength,
            instructions: "Press the barbell"
        )
        context.insert(exercise)
        
        let sessionExercise = SessionExercise(
            exercise: exercise,
            plannedSets: 3,
            plannedReps: 8,
            plannedWeight: 135.0,
            position: 1.0,
            autoPopulateFromLastSession: false
        )
        context.insert(sessionExercise)
        
        // When - Add sets but don't mark as completed
        let set1 = CompletedSet(reps: 8, weight: 135.0, sessionExercise: sessionExercise)
        context.insert(set1)
        
        sessionExercise.updateExerciseCacheOnCompletion()
        
        // Then - Cache should not be updated
        XCTAssertNil(exercise.lastUsedWeight, "Last used weight should remain nil")
        XCTAssertNil(exercise.lastUsedReps, "Last used reps should remain nil")
        XCTAssertNil(exercise.lastTotalVolume, "Last total volume should remain nil")
        XCTAssertNil(exercise.lastUsedDate, "Last used date should remain nil")
        
        print("✅ [ExerciseCachingTests.testExerciseCacheUpdateWithoutCompletion] Test passed")
    }
    
    func testExerciseCacheUpdateWithoutSets() throws {
        print("🧪 [ExerciseCachingTests.testExerciseCacheUpdateWithoutSets] Testing cache update without sets")
        
        // Given
        let exercise = Exercise(
            name: "Bench Press",
            category: .strength,
            instructions: "Press the barbell"
        )
        context.insert(exercise)
        
        let sessionExercise = SessionExercise(
            exercise: exercise,
            plannedSets: 3,
            plannedReps: 8,
            plannedWeight: 135.0,
            position: 1.0,
            autoPopulateFromLastSession: false
        )
        context.insert(sessionExercise)
        
        // When - Mark as completed but no sets
        sessionExercise.isCompleted = true
        sessionExercise.updateExerciseCacheOnCompletion()
        
        // Then - Cache should not be updated
        XCTAssertNil(exercise.lastUsedWeight, "Last used weight should remain nil")
        XCTAssertNil(exercise.lastUsedReps, "Last used reps should remain nil")
        XCTAssertNil(exercise.lastTotalVolume, "Last total volume should remain nil")
        XCTAssertNil(exercise.lastUsedDate, "Last used date should remain nil")
        
        print("✅ [ExerciseCachingTests.testExerciseCacheUpdateWithoutSets] Test passed")
    }
} 