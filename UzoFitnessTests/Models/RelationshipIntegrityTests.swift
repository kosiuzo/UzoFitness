import Foundation
import SwiftData
import Testing
import UzoFitnessCore
@testable import UzoFitness

/// Tests to verify relationship integrity and cascade delete behavior
@MainActor
final class RelationshipIntegrityTests {
    
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
    
    // MARK: - WorkoutSession.totalVolume Tests
    
    @Test("WorkoutSession.totalVolume computed property calculates correctly")
    func testWorkoutSessionTotalVolumeCalculation() async throws {
        print("🔄 [RelationshipIntegrityTests.testWorkoutSessionTotalVolumeCalculation] Starting test")
        
        setUp()
        defer { tearDown() }
        
        // Create test data
        let exercise = TestHelpers.createTestExercise(name: "Test Exercise")
        persistenceController.create(exercise)
        
        let session = TestHelpers.createTestWorkoutSession(title: "Test Session")
        persistenceController.create(session)
        
        // Create session exercise
        let sessionExercise = SessionExercise(
            exercise: exercise,
            plannedSets: 3,
            plannedReps: 10,
            plannedWeight: 100.0,
            position: 1.0,
            session: session,
            autoPopulateFromLastSession: false
        )
        persistenceController.create(sessionExercise)
        
        // Create completed sets
        let set1 = CompletedSet(reps: 10, weight: 100.0, sessionExercise: sessionExercise)
        let set2 = CompletedSet(reps: 8, weight: 105.0, sessionExercise: sessionExercise)
        let set3 = CompletedSet(reps: 6, weight: 110.0, sessionExercise: sessionExercise)
        
        persistenceController.create(set1)
        persistenceController.create(set2)
        persistenceController.create(set3)
        
        // Refresh the session to get updated relationships
        let fetchedSession = persistenceController.fetch(WorkoutSession.self).first { $0.id == session.id }
        #expect(fetchedSession != nil)
        
        // Calculate expected total volume
        // Set 1: 10 reps * 100 lbs = 1000
        // Set 2: 8 reps * 105 lbs = 840
        // Set 3: 6 reps * 110 lbs = 660
        // Total: 2500
        let expectedVolume = (10 * 100.0) + (8 * 105.0) + (6 * 110.0)
        
        #expect(fetchedSession!.totalVolume == expectedVolume)
        
        print("✅ [RelationshipIntegrityTests.testWorkoutSessionTotalVolumeCalculation] Test completed")
    }
    
    @Test("WorkoutSession.totalVolume handles empty session correctly")
    func testWorkoutSessionTotalVolumeWithEmptySession() async throws {
        print("🔄 [RelationshipIntegrityTests.testWorkoutSessionTotalVolumeWithEmptySession] Starting test")
        
        setUp()
        defer { tearDown() }
        
        let session = TestHelpers.createTestWorkoutSession(title: "Empty Session")
        persistenceController.create(session)
        
        #expect(session.totalVolume == 0.0)
        
        print("✅ [RelationshipIntegrityTests.testWorkoutSessionTotalVolumeWithEmptySession] Test completed")
    }
    
    // MARK: - Cascade Delete Tests
    
    @Test("Cascade delete removes session exercises when workout session is deleted")
    func testCascadeDeleteSessionRemovesChildren() async throws {
        print("🔄 [RelationshipIntegrityTests.testCascadeDeleteSessionRemovesChildren] Starting test")
        
        setUp()
        defer { tearDown() }
        
        // Create complete workout setup
        let (exercise, _, _, _, _, session, sessionExercise, completedSet) = 
            TestDataFactories.createCompleteWorkoutSetup(persistenceController: persistenceController)
        
        // Verify all entities exist
        #expect(persistenceController.fetch(WorkoutSession.self).contains { $0.id == session.id })
        #expect(persistenceController.fetch(SessionExercise.self).contains { $0.id == sessionExercise.id })
        #expect(persistenceController.fetch(CompletedSet.self).contains { $0.id == completedSet.id })
        
        // Delete the workout session
        persistenceController.delete(session)
        
        // Verify session is deleted
        #expect(!persistenceController.fetch(WorkoutSession.self).contains { $0.id == session.id })
        
        // Verify related entities are also deleted (cascade delete)
        #expect(!persistenceController.fetch(SessionExercise.self).contains { $0.id == sessionExercise.id })
        #expect(!persistenceController.fetch(CompletedSet.self).contains { $0.id == completedSet.id })
        
        // Verify exercise still exists (should not be deleted)
        #expect(persistenceController.fetch(Exercise.self).contains { $0.id == exercise.id })
        
        print("✅ [RelationshipIntegrityTests.testCascadeDeleteSessionRemovesChildren] Test completed")
    }
    
    @Test("Cascade delete removes completed sets when session exercise is deleted")
    func testCascadeDeleteSessionExerciseRemovesCompletedSets() async throws {
        print("🔄 [RelationshipIntegrityTests.testCascadeDeleteSessionExerciseRemovesCompletedSets] Starting test")
        
        setUp()
        defer { tearDown() }
        
        // Create test data
        let exercise = TestHelpers.createTestExercise(name: "Test Exercise")
        persistenceController.create(exercise)
        
        let session = TestHelpers.createTestWorkoutSession(title: "Test Session")
        persistenceController.create(session)
        
        let sessionExercise = SessionExercise(
            exercise: exercise,
            plannedSets: 2,
            plannedReps: 10,
            position: 1.0,
            session: session,
            autoPopulateFromLastSession: false
        )
        persistenceController.create(sessionExercise)
        
        // Create multiple completed sets
        let set1 = CompletedSet(reps: 10, weight: 100.0, sessionExercise: sessionExercise)
        let set2 = CompletedSet(reps: 8, weight: 105.0, sessionExercise: sessionExercise)
        
        persistenceController.create(set1)
        persistenceController.create(set2)
        
        // Verify sets exist
        #expect(persistenceController.fetch(CompletedSet.self).contains { $0.id == set1.id })
        #expect(persistenceController.fetch(CompletedSet.self).contains { $0.id == set2.id })
        
        // Delete the session exercise
        persistenceController.delete(sessionExercise)
        
        // Verify session exercise is deleted
        #expect(!persistenceController.fetch(SessionExercise.self).contains { $0.id == sessionExercise.id })
        
        // Verify completed sets are also deleted (cascade delete)
        #expect(!persistenceController.fetch(CompletedSet.self).contains { $0.id == set1.id })
        #expect(!persistenceController.fetch(CompletedSet.self).contains { $0.id == set2.id })
        
        // Verify session and exercise still exist
        #expect(persistenceController.fetch(WorkoutSession.self).contains { $0.id == session.id })
        #expect(persistenceController.fetch(Exercise.self).contains { $0.id == exercise.id })
        
        print("✅ [RelationshipIntegrityTests.testCascadeDeleteSessionExerciseRemovesCompletedSets] Test completed")
    }
    
    @Test("No orphaned objects remain after complex deletion")
    func testNoOrphanedObjectsAfterComplexDeletion() async throws {
        print("🔄 [RelationshipIntegrityTests.testNoOrphanedObjectsAfterComplexDeletion] Starting test")
        
        setUp()
        defer { tearDown() }
        
        // Create multiple workout sessions with exercises and sets
        var sessions: [WorkoutSession] = []
        var sessionExercises: [SessionExercise] = []
        var completedSets: [CompletedSet] = []
        
        let exercise = TestHelpers.createTestExercise(name: "Test Exercise")
        persistenceController.create(exercise)
        
        // Create 3 workout sessions
        for i in 1...3 {
            let session = TestHelpers.createTestWorkoutSession(title: "Session \(i)")
            persistenceController.create(session)
            sessions.append(session)
            
            // Create 2 session exercises per session
            for j in 1...2 {
                let sessionExercise = SessionExercise(
                    exercise: exercise,
                    plannedSets: 2,
                    plannedReps: 10,
                    position: Double(j),
                    session: session,
                    autoPopulateFromLastSession: false
                )
                persistenceController.create(sessionExercise)
                sessionExercises.append(sessionExercise)
                
                // Create 2 completed sets per session exercise
                for k in 1...2 {
                    let set = CompletedSet(
                        reps: 10,
                        weight: Double(100 + k),
                        sessionExercise: sessionExercise
                    )
                    persistenceController.create(set)
                    completedSets.append(set)
                }
            }
        }
        
        // Verify all objects were created
        #expect(persistenceController.fetch(WorkoutSession.self).count >= 3)
        #expect(persistenceController.fetch(SessionExercise.self).count >= 6)
        #expect(persistenceController.fetch(CompletedSet.self).count >= 12)
        
        // Delete the first session (should cascade delete 2 session exercises and 4 sets)
        persistenceController.delete(sessions[0])
        
        // Verify cascade deletion worked correctly
        let remainingSessions = persistenceController.fetch(WorkoutSession.self)
        let remainingSessionExercises = persistenceController.fetch(SessionExercise.self)
        let remainingCompletedSets = persistenceController.fetch(CompletedSet.self)
        
        #expect(remainingSessions.count == 2)
        #expect(remainingSessionExercises.count == 4)
        #expect(remainingCompletedSets.count == 8)
        
        // Verify no orphaned session exercises (all should have a session)
        for sessionExercise in remainingSessionExercises {
            #expect(sessionExercise.session != nil)
            #expect(remainingSessions.contains { $0.id == sessionExercise.session?.id })
        }
        
        // Verify no orphaned completed sets (all should have a session exercise)
        for completedSet in remainingCompletedSets {
            #expect(completedSet.sessionExercise != nil)
            #expect(remainingSessionExercises.contains { $0.id == completedSet.sessionExercise?.id })
        }
        
        print("✅ [RelationshipIntegrityTests.testNoOrphanedObjectsAfterComplexDeletion] Test completed")
    }
    
    // MARK: - Relationship Consistency Tests
    
    @Test("SessionExercise.totalVolume calculation is consistent with individual sets")
    func testSessionExerciseTotalVolumeConsistency() async throws {
        print("🔄 [RelationshipIntegrityTests.testSessionExerciseTotalVolumeConsistency] Starting test")
        
        setUp()
        defer { tearDown() }
        
        let exercise = TestHelpers.createTestExercise(name: "Test Exercise")
        persistenceController.create(exercise)
        
        let session = TestHelpers.createTestWorkoutSession(title: "Test Session")
        persistenceController.create(session)
        
        let sessionExercise = SessionExercise(
            exercise: exercise,
            plannedSets: 3,
            plannedReps: 10,
            position: 1.0,
            session: session,
            autoPopulateFromLastSession: false
        )
        persistenceController.create(sessionExercise)
        
        // Create sets with known values
        let setData = [(reps: 12, weight: 135.0), (reps: 10, weight: 140.0), (reps: 8, weight: 145.0)]
        var expectedTotalVolume = 0.0
        
        for (reps, weight) in setData {
            let set = CompletedSet(reps: reps, weight: weight, sessionExercise: sessionExercise)
            persistenceController.create(set)
            expectedTotalVolume += Double(reps) * weight
        }
        
        // Refresh sessionExercise to get updated relationships
        let fetchedSessionExercise = persistenceController.fetch(SessionExercise.self).first { $0.id == sessionExercise.id }
        #expect(fetchedSessionExercise != nil)
        
        // Verify the total volume calculation
        #expect(fetchedSessionExercise!.totalVolume == expectedTotalVolume)
        
        // Verify individual set calculations
        let fetchedSets = persistenceController.fetch(CompletedSet.self).filter { $0.sessionExercise?.id == sessionExercise.id }
        var manualTotal = 0.0
        for set in fetchedSets {
            manualTotal += Double(set.reps) * set.weight
        }
        
        #expect(manualTotal == expectedTotalVolume)
        #expect(fetchedSessionExercise!.totalVolume == manualTotal)
        
        print("✅ [RelationshipIntegrityTests.testSessionExerciseTotalVolumeConsistency] Test completed")
    }
    
    @Test("Relationship bidirectionality is maintained")
    func testRelationshipBidirectionality() async throws {
        print("🔄 [RelationshipIntegrityTests.testRelationshipBidirectionality] Starting test")
        
        setUp()
        defer { tearDown() }
        
        let exercise = TestHelpers.createTestExercise(name: "Test Exercise")
        persistenceController.create(exercise)
        
        let session = TestHelpers.createTestWorkoutSession(title: "Test Session")
        persistenceController.create(session)
        
        let sessionExercise = SessionExercise(
            exercise: exercise,
            plannedSets: 1,
            plannedReps: 10,
            position: 1.0,
            session: session,
            autoPopulateFromLastSession: false
        )
        persistenceController.create(sessionExercise)
        
        let completedSet = CompletedSet(reps: 10, weight: 100.0, sessionExercise: sessionExercise)
        persistenceController.create(completedSet)
        
        // Refresh all objects to ensure relationships are loaded
        let fetchedSession = persistenceController.fetch(WorkoutSession.self).first { $0.id == session.id }!
        let fetchedSessionExercise = persistenceController.fetch(SessionExercise.self).first { $0.id == sessionExercise.id }!
        let fetchedCompletedSet = persistenceController.fetch(CompletedSet.self).first { $0.id == completedSet.id }!
        
        // Test Session -> SessionExercise relationship
        #expect(fetchedSession.sessionExercises.contains { $0.id == sessionExercise.id })
        
        // Test SessionExercise -> Session relationship  
        #expect(fetchedSessionExercise.session?.id == session.id)
        
        // Test SessionExercise -> CompletedSet relationship
        #expect(fetchedSessionExercise.completedSets.contains { $0.id == completedSet.id })
        
        // Test CompletedSet -> SessionExercise relationship
        #expect(fetchedCompletedSet.sessionExercise?.id == sessionExercise.id)
        
        print("✅ [RelationshipIntegrityTests.testRelationshipBidirectionality] Test completed")
    }
}