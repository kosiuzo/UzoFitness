import Foundation
import SwiftData
import Testing
import UzoFitnessCore
@testable import UzoFitness

/// Tests to verify Exercise model caching behavior and auto-population functionality
@MainActor
final class ExerciseCachingTests {
    
    // MARK: - Test Properties
    private var persistenceController: InMemoryPersistenceController!
    
    // MARK: - Setup and Teardown
    
    private func setUp() {
        persistenceController = InMemoryPersistenceController()
        persistenceController.cleanupTestData()
    }
    
    private func tearDown() {
        persistenceController?.cleanupTestData()
        persistenceController = nil
    }
    
    // MARK: - Initialization and Default Values Tests
    
    @Test("Exercise initializes with nil cached values")
    func testExerciseInitializesWithNilCachedValues() async throws {
        print("🔄 [ExerciseCachingTests.testExerciseInitializesWithNilCachedValues] Starting test")
        
        setUp()
        defer { tearDown() }
        
        let exercise = Exercise(
            name: "Bench Press",
            category: .strength,
            instructions: "Chest exercise"
        )
        
        // Verify all cached values are nil initially
        #expect(exercise.lastUsedWeight == nil)
        #expect(exercise.lastUsedReps == nil)
        #expect(exercise.lastTotalVolume == nil)
        #expect(exercise.lastUsedDate == nil)
        
        // Verify suggested starting values are nil when no cache exists
        let suggestedValues = exercise.suggestedStartingValues
        #expect(suggestedValues.weight == nil)
        #expect(suggestedValues.reps == nil)
        #expect(suggestedValues.totalVolume == nil)
        
        print("✅ [ExerciseCachingTests.testExerciseInitializesWithNilCachedValues] Test completed")
    }
    
    @Test("Exercise can be initialized with specific cached values")
    func testExerciseInitializesWithSpecificCachedValues() async throws {
        print("🔄 [ExerciseCachingTests.testExerciseInitializesWithSpecificCachedValues] Starting test")
        
        setUp()
        defer { tearDown() }
        
        let testDate = Date()
        let exercise = Exercise(
            name: "Squat",
            category: .strength,
            instructions: "Leg exercise",
            lastUsedWeight: 225.0,
            lastUsedReps: 8,
            lastTotalVolume: 1800.0,
            lastUsedDate: testDate
        )
        
        // Verify cached values are set correctly
        #expect(exercise.lastUsedWeight == 225.0)
        #expect(exercise.lastUsedReps == 8)
        #expect(exercise.lastTotalVolume == 1800.0)
        #expect(exercise.lastUsedDate == testDate)
        
        // Verify suggested starting values return cached values
        let suggestedValues = exercise.suggestedStartingValues
        #expect(suggestedValues.weight == 225.0)
        #expect(suggestedValues.reps == 8)
        #expect(suggestedValues.totalVolume == 1800.0)
        
        print("✅ [ExerciseCachingTests.testExerciseInitializesWithSpecificCachedValues] Test completed")
    }
    
    // MARK: - Manual Cache Update Tests
    
    @Test("Exercise cache can be manually updated")
    func testExerciseCacheManualUpdate() async throws {
        print("🔄 [ExerciseCachingTests.testExerciseCacheManualUpdate] Starting test")
        
        setUp()
        defer { tearDown() }
        
        let exercise = Exercise(
            name: "Deadlift",
            category: .strength,
            instructions: "Posterior chain exercise"
        )
        
        // Insert into persistence context
        persistenceController.create(exercise)
        
        // Verify initial state
        #expect(exercise.lastUsedWeight == nil)
        #expect(exercise.lastUsedReps == nil)
        #expect(exercise.lastTotalVolume == nil)
        #expect(exercise.lastUsedDate == nil)
        
        // Manually update cache values
        let updateDate = Date()
        exercise.lastUsedWeight = 315.0
        exercise.lastUsedReps = 5
        exercise.lastTotalVolume = 1575.0
        exercise.lastUsedDate = updateDate
        
        // Save changes
        persistenceController.save()
        
        // Fetch and verify updates persist
        let fetchedExercises = persistenceController.fetch(Exercise.self)
        let updatedExercise = fetchedExercises.first { $0.id == exercise.id }
        
        #expect(updatedExercise?.lastUsedWeight == 315.0)
        #expect(updatedExercise?.lastUsedReps == 5)
        #expect(updatedExercise?.lastTotalVolume == 1575.0)
        #expect(updatedExercise?.lastUsedDate == updateDate)
        
        print("✅ [ExerciseCachingTests.testExerciseCacheManualUpdate] Test completed")
    }
    
    @Test("Exercise cache updates are independent between exercises")
    func testExerciseCacheIndependence() async throws {
        print("🔄 [ExerciseCachingTests.testExerciseCacheIndependence] Starting test")
        
        setUp()
        defer { tearDown() }
        
        // Create two different exercises
        let exercise1 = Exercise(
            name: "Bench Press",
            category: .strength,
            instructions: "Chest exercise"
        )
        
        let exercise2 = Exercise(
            name: "Squat",
            category: .strength,
            instructions: "Leg exercise" 
        )
        
        persistenceController.create(exercise1)
        persistenceController.create(exercise2)
        
        // Update cache for exercise1 only
        let updateDate = Date()
        exercise1.lastUsedWeight = 185.0
        exercise1.lastUsedReps = 10
        exercise1.lastTotalVolume = 1850.0
        exercise1.lastUsedDate = updateDate
        
        persistenceController.save()
        
        // Verify exercise1 has cached values
        #expect(exercise1.lastUsedWeight == 185.0)
        #expect(exercise1.lastUsedReps == 10)
        #expect(exercise1.lastTotalVolume == 1850.0)
        #expect(exercise1.lastUsedDate == updateDate)
        
        // Verify exercise2 still has nil cached values
        #expect(exercise2.lastUsedWeight == nil)
        #expect(exercise2.lastUsedReps == nil)
        #expect(exercise2.lastTotalVolume == nil)
        #expect(exercise2.lastUsedDate == nil)
        
        print("✅ [ExerciseCachingTests.testExerciseCacheIndependence] Test completed")
    }
    
    // MARK: - SessionExercise Auto-Population Tests
    
    @Test("SessionExercise auto-populates from exercise cache")
    func testSessionExerciseAutoPopulatesFromCache() async throws {
        print("🔄 [ExerciseCachingTests.testSessionExerciseAutoPopulatesFromCache] Starting test")
        
        setUp()
        defer { tearDown() }
        
        // Create exercise with cached values
        let testDate = Date().addingTimeInterval(-86400) // 1 day ago
        let exercise = Exercise(
            name: "Overhead Press",
            category: .strength,
            instructions: "Shoulder exercise",
            lastUsedWeight: 135.0,
            lastUsedReps: 8,
            lastTotalVolume: 1080.0,
            lastUsedDate: testDate
        )
        
        persistenceController.create(exercise)
        
        // Create SessionExercise with auto-population enabled (default)
        let sessionExercise = SessionExercise(
            exercise: exercise,
            plannedSets: 3,
            position: 1.0,
            autoPopulateFromLastSession: true
        )
        
        // Verify auto-population worked
        #expect(sessionExercise.plannedReps == 8) // From cached reps
        #expect(sessionExercise.plannedWeight == 135.0) // From cached weight
        #expect(sessionExercise.previousTotalVolume == 1080.0) // From cached total volume
        #expect(sessionExercise.previousSessionDate == testDate) // From cached date
        
        print("✅ [ExerciseCachingTests.testSessionExerciseAutoPopulatesFromCache] Test completed")
    }
    
    @Test("SessionExercise uses defaults when no cache exists")
    func testSessionExerciseUsesDefaultsWithoutCache() async throws {
        print("🔄 [ExerciseCachingTests.testSessionExerciseUsesDefaultsWithoutCache] Starting test")
        
        setUp()
        defer { tearDown() }
        
        // Create exercise without cached values
        let exercise = Exercise(
            name: "Pull-ups",
            category: .strength,
            instructions: "Back exercise"
        )
        
        persistenceController.create(exercise)
        
        // Create SessionExercise with auto-population enabled
        let sessionExercise = SessionExercise(
            exercise: exercise,
            plannedSets: 3,
            position: 1.0,
            autoPopulateFromLastSession: true
        )
        
        // Verify defaults are used when no cache exists
        #expect(sessionExercise.plannedReps == 10) // Default value
        #expect(sessionExercise.plannedWeight == nil) // No cached weight
        #expect(sessionExercise.previousTotalVolume == nil) // No cached volume
        #expect(sessionExercise.previousSessionDate == nil) // No cached date
        
        print("✅ [ExerciseCachingTests.testSessionExerciseUsesDefaultsWithoutCache] Test completed")
    }
    
    @Test("SessionExercise respects explicit values over auto-population")
    func testSessionExerciseRespectsExplicitValues() async throws {
        print("🔄 [ExerciseCachingTests.testSessionExerciseRespectsExplicitValues] Starting test")
        
        setUp()
        defer { tearDown() }
        
        // Create exercise with cached values
        let exercise = Exercise(
            name: "Barbell Row",
            category: .strength,
            instructions: "Back exercise",
            lastUsedWeight: 155.0,
            lastUsedReps: 8,
            lastTotalVolume: 1240.0,
            lastUsedDate: Date().addingTimeInterval(-86400)
        )
        
        persistenceController.create(exercise)
        
        // Create SessionExercise with explicit values that should override cache
        let sessionExercise = SessionExercise(
            exercise: exercise,
            plannedSets: 4,
            plannedReps: 12, // Explicit value should override cached 8 reps
            plannedWeight: 165.0, // Explicit value should override cached 155.0 weight
            position: 1.0,
            autoPopulateFromLastSession: true
        )
        
        // Verify explicit values take precedence over cached values
        #expect(sessionExercise.plannedReps == 12) // Explicit value used
        #expect(sessionExercise.plannedWeight == 165.0) // Explicit value used
        #expect(sessionExercise.previousTotalVolume == 1240.0) // Still auto-populated from cache
        
        print("✅ [ExerciseCachingTests.testSessionExerciseRespectsExplicitValues] Test completed")
    }
    
    @Test("SessionExercise disables auto-population when requested")
    func testSessionExerciseDisablesAutoPopulation() async throws {
        print("🔄 [ExerciseCachingTests.testSessionExerciseDisablesAutoPopulation] Starting test")
        
        setUp()
        defer { tearDown() }
        
        // Create exercise with cached values
        let exercise = Exercise(
            name: "Lat Pulldown",
            category: .strength,
            instructions: "Back exercise",
            lastUsedWeight: 120.0,
            lastUsedReps: 12,
            lastTotalVolume: 1440.0,
            lastUsedDate: Date().addingTimeInterval(-86400)
        )
        
        persistenceController.create(exercise)
        
        // Create SessionExercise with auto-population disabled
        let sessionExercise = SessionExercise(
            exercise: exercise,
            plannedSets: 3,
            position: 1.0,
            autoPopulateFromLastSession: false
        )
        
        // Verify auto-population was disabled
        #expect(sessionExercise.plannedReps == 10) // Default value, not cached
        #expect(sessionExercise.plannedWeight == nil) // Not auto-populated
        #expect(sessionExercise.previousTotalVolume == nil) // Not auto-populated
        #expect(sessionExercise.previousSessionDate == nil) // Not auto-populated
        
        print("✅ [ExerciseCachingTests.testSessionExerciseDisablesAutoPopulation] Test completed")
    }
    
    // MARK: - Cache Update After Session Completion Tests
    
    @Test("SessionExercise updates exercise cache on completion")
    func testSessionExerciseUpdatesCacheOnCompletion() async throws {
        print("🔄 [ExerciseCachingTests.testSessionExerciseUpdatesCacheOnCompletion] Starting test")
        
        setUp()
        defer { tearDown() }
        
        // Create exercise without cached values
        let exercise = Exercise(
            name: "Incline Press",
            category: .strength,
            instructions: "Upper chest exercise"
        )
        
        persistenceController.create(exercise)
        
        // Create SessionExercise
        let sessionExercise = SessionExercise(
            exercise: exercise,
            plannedSets: 3,
            plannedReps: 10,
            plannedWeight: 155.0,
            position: 1.0
        )
        
        persistenceController.create(sessionExercise)
        
        // Create completed sets
        let set1 = CompletedSet(reps: 10, weight: 155.0, position: 1, sessionExercise: sessionExercise)
        let set2 = CompletedSet(reps: 8, weight: 155.0, position: 2, sessionExercise: sessionExercise)
        let set3 = CompletedSet(reps: 6, weight: 155.0, position: 3, sessionExercise: sessionExercise)
        
        persistenceController.create(set1)
        persistenceController.create(set2)
        persistenceController.create(set3)
        
        // Add sets to session exercise and mark as completed
        sessionExercise.completedSets = [set1, set2, set3]
        sessionExercise.isCompleted = true
        
        persistenceController.save()
        
        // Verify exercise cache is still empty before update
        #expect(exercise.lastUsedWeight == nil)
        #expect(exercise.lastUsedReps == nil)
        #expect(exercise.lastTotalVolume == nil)
        #expect(exercise.lastUsedDate == nil)
        
        // Update exercise cache on completion
        sessionExercise.updateExerciseCacheOnCompletion()
        
        // Verify exercise cache was updated
        let expectedTotalVolume = 10.0 * 155.0 + 8.0 * 155.0 + 6.0 * 155.0 // 3720.0
        #expect(exercise.lastUsedWeight == 155.0) // From last set
        #expect(exercise.lastUsedReps == 6) // From last set
        #expect(exercise.lastTotalVolume == expectedTotalVolume)
        #expect(exercise.lastUsedDate != nil) // Should be set to session date or creation time
        
        print("✅ [ExerciseCachingTests.testSessionExerciseUpdatesCacheOnCompletion] Test completed")
    }
    
    @Test("SessionExercise does not update cache when not completed")
    func testSessionExerciseDoesNotUpdateCacheWhenNotCompleted() async throws {
        print("🔄 [ExerciseCachingTests.testSessionExerciseDoesNotUpdateCacheWhenNotCompleted] Starting test")
        
        setUp()
        defer { tearDown() }
        
        // Create exercise with existing cached values
        let originalDate = Date().addingTimeInterval(-86400)
        let exercise = Exercise(
            name: "Leg Press",
            category: .strength,
            instructions: "Leg exercise",
            lastUsedWeight: 400.0,
            lastUsedReps: 15,
            lastTotalVolume: 6000.0,
            lastUsedDate: originalDate
        )
        
        persistenceController.create(exercise)
        
        // Create SessionExercise that is not completed
        let sessionExercise = SessionExercise(
            exercise: exercise,
            plannedSets: 3,
            plannedReps: 12,
            plannedWeight: 450.0,
            position: 1.0
        )
        
        sessionExercise.isCompleted = false // Explicitly not completed
        persistenceController.create(sessionExercise)
        
        // Create some completed sets but don't mark session as completed
        let set1 = CompletedSet(reps: 12, weight: 450.0, position: 1, sessionExercise: sessionExercise)
        persistenceController.create(set1)
        sessionExercise.completedSets = [set1]
        
        persistenceController.save()
        
        // Attempt to update cache (should not update)
        sessionExercise.updateExerciseCacheOnCompletion()
        
        // Verify exercise cache was NOT updated (original values preserved)
        #expect(exercise.lastUsedWeight == 400.0) // Original value
        #expect(exercise.lastUsedReps == 15) // Original value
        #expect(exercise.lastTotalVolume == 6000.0) // Original value
        #expect(exercise.lastUsedDate == originalDate) // Original value
        
        print("✅ [ExerciseCachingTests.testSessionExerciseDoesNotUpdateCacheWhenNotCompleted] Test completed")
    }
    
    @Test("SessionExercise does not update cache with no completed sets")
    func testSessionExerciseDoesNotUpdateCacheWithNoSets() async throws {
        print("🔄 [ExerciseCachingTests.testSessionExerciseDoesNotUpdateCacheWithNoSets] Starting test")
        
        setUp()
        defer { tearDown() }
        
        // Create exercise with existing cached values
        let originalDate = Date().addingTimeInterval(-86400)
        let exercise = Exercise(
            name: "Calf Raise",
            category: .strength,
            instructions: "Calf exercise",
            lastUsedWeight: 200.0,
            lastUsedReps: 20,
            lastTotalVolume: 4000.0,
            lastUsedDate: originalDate
        )
        
        persistenceController.create(exercise)
        
        // Create SessionExercise marked as completed but with no sets
        let sessionExercise = SessionExercise(
            exercise: exercise,
            plannedSets: 3,
            plannedReps: 15,
            plannedWeight: 220.0,
            position: 1.0
        )
        
        sessionExercise.isCompleted = true // Marked as completed
        sessionExercise.completedSets = [] // But no completed sets
        persistenceController.create(sessionExercise)
        persistenceController.save()
        
        // Attempt to update cache (should not update due to no sets)
        sessionExercise.updateExerciseCacheOnCompletion()
        
        // Verify exercise cache was NOT updated (original values preserved)
        #expect(exercise.lastUsedWeight == 200.0) // Original value
        #expect(exercise.lastUsedReps == 20) // Original value
        #expect(exercise.lastTotalVolume == 4000.0) // Original value
        #expect(exercise.lastUsedDate == originalDate) // Original value
        
        print("✅ [ExerciseCachingTests.testSessionExerciseDoesNotUpdateCacheWithNoSets] Test completed")
    }
    
    // MARK: - Volume Calculation Tests
    
    @Test("SessionExercise calculates total volume correctly")
    func testSessionExerciseCalculatesTotalVolumeCorrectly() async throws {
        print("🔄 [ExerciseCachingTests.testSessionExerciseCalculatesTotalVolumeCorrectly] Starting test")
        
        setUp()
        defer { tearDown() }
        
        let exercise = Exercise(
            name: "Dumbbell Press",
            category: .strength,
            instructions: "Chest exercise"
        )
        
        persistenceController.create(exercise)
        
        let sessionExercise = SessionExercise(
            exercise: exercise,
            plannedSets: 4,
            position: 1.0
        )
        
        persistenceController.create(sessionExercise)
        
        // Create sets with different weights and reps
        let set1 = CompletedSet(reps: 12, weight: 60.0, position: 1, sessionExercise: sessionExercise) // 720
        let set2 = CompletedSet(reps: 10, weight: 65.0, position: 2, sessionExercise: sessionExercise) // 650
        let set3 = CompletedSet(reps: 8, weight: 70.0, position: 3, sessionExercise: sessionExercise)  // 560
        let set4 = CompletedSet(reps: 6, weight: 75.0, position: 4, sessionExercise: sessionExercise)  // 450
        
        persistenceController.create(set1)
        persistenceController.create(set2)
        persistenceController.create(set3)
        persistenceController.create(set4)
        
        sessionExercise.completedSets = [set1, set2, set3, set4]
        persistenceController.save()
        
        // Verify total volume calculation
        let expectedVolume = 720.0 + 650.0 + 560.0 + 450.0 // 2380.0
        #expect(sessionExercise.totalVolume == expectedVolume)
        
        print("✅ [ExerciseCachingTests.testSessionExerciseCalculatesTotalVolumeCorrectly] Test completed")
    }
    
    @Test("Exercise cache reflects most recent session data")
    func testExerciseCacheReflectsMostRecentSession() async throws {
        print("🔄 [ExerciseCachingTests.testExerciseCacheReflectsMostRecentSession] Starting test")
        
        setUp()
        defer { tearDown() }
        
        let exercise = Exercise(
            name: "Bulgarian Split Squat",
            category: .strength,
            instructions: "Single leg exercise"
        )
        
        persistenceController.create(exercise)
        
        // First session (older)
        let firstSession = SessionExercise(
            exercise: exercise,
            plannedSets: 3,
            position: 1.0
        )
        
        persistenceController.create(firstSession)
        
        let firstSet = CompletedSet(reps: 10, weight: 25.0, position: 1, sessionExercise: firstSession)
        persistenceController.create(firstSet)
        firstSession.completedSets = [firstSet]
        firstSession.isCompleted = true
        
        // Update cache with first session
        firstSession.updateExerciseCacheOnCompletion()
        
        // Verify first session updated the cache
        #expect(exercise.lastUsedWeight == 25.0)
        #expect(exercise.lastUsedReps == 10)
        #expect(exercise.lastTotalVolume == 250.0)
        
        // Second session (more recent) - should override the cache
        let secondSession = SessionExercise(
            exercise: exercise,
            plannedSets: 3,
            position: 1.0
        )
        
        persistenceController.create(secondSession)
        
        let secondSet1 = CompletedSet(reps: 12, weight: 30.0, position: 1, sessionExercise: secondSession)
        let secondSet2 = CompletedSet(reps: 10, weight: 30.0, position: 2, sessionExercise: secondSession)
        persistenceController.create(secondSet1)
        persistenceController.create(secondSet2)
        secondSession.completedSets = [secondSet1, secondSet2]
        secondSession.isCompleted = true
        
        // Update cache with second session
        secondSession.updateExerciseCacheOnCompletion()
        
        // Verify cache now reflects the more recent session
        #expect(exercise.lastUsedWeight == 30.0) // From second session's last set
        #expect(exercise.lastUsedReps == 10) // From second session's last set
        #expect(exercise.lastTotalVolume == 660.0) // 12*30 + 10*30 = 660
        
        print("✅ [ExerciseCachingTests.testExerciseCacheReflectsMostRecentSession] Test completed")
    }
}