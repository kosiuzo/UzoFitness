import Foundation
import SwiftData
import Testing
import UzoFitnessCore
@testable import UzoFitness

/// Tests to verify workout domain business logic and volume calculations
@MainActor
final class WorkoutDomainTests {
    
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
    
    // MARK: - Volume Calculation Tests
    
    @Test("Total volume calculation per exercise in session")
    func testTotalVolumePerExerciseAndSession() async throws {
        print("🔄 [WorkoutDomainTests.testTotalVolumePerExerciseAndSession] Starting test")
        
        setUp()
        defer { tearDown() }
        
        // Create test data
        let exercise1 = TestHelpers.createTestExercise(name: "Bench Press")
        let exercise2 = TestHelpers.createTestExercise(name: "Squat")
        persistenceController.create(exercise1)
        persistenceController.create(exercise2)
        
        let session = TestHelpers.createTestWorkoutSession(title: "Upper/Lower Day")
        persistenceController.create(session)
        
        // Create first exercise in session (Bench Press)
        let sessionExercise1 = SessionExercise(
            exercise: exercise1,
            plannedSets: 3,
            plannedReps: 10,
            position: 1.0,
            session: session,
            autoPopulateFromLastSession: false
        )
        persistenceController.create(sessionExercise1)
        
        // Add sets for bench press
        let set1_1 = CompletedSet(reps: 10, weight: 135.0, sessionExercise: sessionExercise1)
        let set1_2 = CompletedSet(reps: 8, weight: 145.0, sessionExercise: sessionExercise1)
        let set1_3 = CompletedSet(reps: 6, weight: 155.0, sessionExercise: sessionExercise1)
        
        persistenceController.create(set1_1)
        persistenceController.create(set1_2)
        persistenceController.create(set1_3)
        
        // Create second exercise in session (Squat)
        let sessionExercise2 = SessionExercise(
            exercise: exercise2,
            plannedSets: 2,
            plannedReps: 12,
            position: 2.0,
            session: session,
            autoPopulateFromLastSession: false
        )
        persistenceController.create(sessionExercise2)
        
        // Add sets for squat
        let set2_1 = CompletedSet(reps: 12, weight: 185.0, sessionExercise: sessionExercise2)
        let set2_2 = CompletedSet(reps: 10, weight: 195.0, sessionExercise: sessionExercise2)
        
        persistenceController.create(set2_1)
        persistenceController.create(set2_2)
        
        // Refresh objects to get updated relationships
        let fetchedSessionExercise1 = persistenceController.fetch(SessionExercise.self).first { $0.id == sessionExercise1.id }!
        let fetchedSessionExercise2 = persistenceController.fetch(SessionExercise.self).first { $0.id == sessionExercise2.id }!
        let fetchedSession = persistenceController.fetch(WorkoutSession.self).first { $0.id == session.id }!
        
        // Calculate expected volumes
        // Bench Press: (10 * 135) + (8 * 145) + (6 * 155) = 1350 + 1160 + 930 = 3440
        let bench1 = 10.0 * 135.0
        let bench2 = 8.0 * 145.0
        let bench3 = 6.0 * 155.0
        let expectedBenchVolume = bench1 + bench2 + bench3
        
        // Squat: (12 * 185) + (10 * 195) = 2220 + 1950 = 4170
        let squat1 = 12.0 * 185.0
        let squat2 = 10.0 * 195.0
        let expectedSquatVolume = squat1 + squat2
        
        // Total session volume
        let expectedTotalVolume = expectedBenchVolume + expectedSquatVolume
        
        // Verify individual exercise volumes
        #expect(fetchedSessionExercise1.totalVolume == expectedBenchVolume)
        #expect(fetchedSessionExercise2.totalVolume == expectedSquatVolume)
        
        // Verify total session volume
        #expect(fetchedSession.totalVolume == expectedTotalVolume)
        
        print("✅ [WorkoutDomainTests.testTotalVolumePerExerciseAndSession] Test completed")
    }
    
    @Test("Volume calculation with weighted exercises")
    func testAddWeightedVolume() async throws {
        print("🔄 [WorkoutDomainTests.testAddWeightedVolume] Starting test")
        
        setUp()
        defer { tearDown() }
        
        let exercise = TestHelpers.createTestExercise(name: "Deadlift")
        persistenceController.create(exercise)
        
        let session = TestHelpers.createTestWorkoutSession(title: "Pull Day")
        persistenceController.create(session)
        
        let sessionExercise = SessionExercise(
            exercise: exercise,
            plannedSets: 4,
            plannedReps: 5,
            position: 1.0,
            session: session,
            autoPopulateFromLastSession: false
        )
        persistenceController.create(sessionExercise)
        
        // Progressive overload sets with increasing weight
        let sets = [
            (reps: 5, weight: 225.0),
            (reps: 5, weight: 275.0),
            (reps: 3, weight: 315.0),
            (reps: 1, weight: 365.0)
        ]
        
        var expectedVolume = 0.0
        for (reps, weight) in sets {
            let set = CompletedSet(reps: reps, weight: weight, sessionExercise: sessionExercise)
            persistenceController.create(set)
            expectedVolume += Double(reps) * weight
        }
        
        // Refresh to get updated relationships
        let fetchedSessionExercise = persistenceController.fetch(SessionExercise.self).first { $0.id == sessionExercise.id }!
        
        // Expected: (5*225) + (5*275) + (3*315) + (1*365) = 1125 + 1375 + 945 + 365 = 3810
        let vol1 = 5.0 * 225.0
        let vol2 = 5.0 * 275.0
        let vol3 = 3.0 * 315.0
        let vol4 = 1.0 * 365.0
        let calculatedExpected = vol1 + vol2 + vol3 + vol4
        
        #expect(fetchedSessionExercise.totalVolume == expectedVolume)
        #expect(fetchedSessionExercise.totalVolume == calculatedExpected)
        
        print("✅ [WorkoutDomainTests.testAddWeightedVolume] Test completed")
    }
    
    @Test("Volume calculation for bodyweight exercises")
    func testBodyweightExerciseVolume() async throws {
        print("🔄 [WorkoutDomainTests.testBodyweightExerciseVolume] Starting test")
        
        setUp()
        defer { tearDown() }
        
        let exercise = TestHelpers.createTestExercise(name: "Push-ups", category: .strength)
        persistenceController.create(exercise)
        
        let session = TestHelpers.createTestWorkoutSession(title: "Bodyweight Day")
        persistenceController.create(session)
        
        let sessionExercise = SessionExercise(
            exercise: exercise,
            plannedSets: 3,
            plannedReps: 20,
            position: 1.0,
            session: session,
            autoPopulateFromLastSession: false
        )
        persistenceController.create(sessionExercise)
        
        // Bodyweight exercises use 0 weight, volume is based on reps only
        let sets = [
            (reps: 20, weight: 0.0),
            (reps: 18, weight: 0.0),
            (reps: 15, weight: 0.0)
        ]
        
        for (reps, weight) in sets {
            let set = CompletedSet(reps: reps, weight: weight, sessionExercise: sessionExercise)
            persistenceController.create(set)
        }
        
        // Refresh to get updated relationships
        let fetchedSessionExercise = persistenceController.fetch(SessionExercise.self).first { $0.id == sessionExercise.id }!
        
        // For bodyweight exercises with 0 weight, volume should be 0
        let bodySet1 = 20.0 * 0.0
        let bodySet2 = 18.0 * 0.0
        let bodySet3 = 15.0 * 0.0
        let expectedVolume = bodySet1 + bodySet2 + bodySet3
        
        #expect(fetchedSessionExercise.totalVolume == expectedVolume)
        #expect(fetchedSessionExercise.totalVolume == 0.0)
        
        print("✅ [WorkoutDomainTests.testBodyweightExerciseVolume] Test completed")
    }
    
    @Test("Volume calculation for weighted bodyweight exercises")
    func testWeightedBodyweightExerciseVolume() async throws {
        print("🔄 [WorkoutDomainTests.testWeightedBodyweightExerciseVolume] Starting test")
        
        setUp()
        defer { tearDown() }
        
        let exercise = TestHelpers.createTestExercise(name: "Weighted Pull-ups", category: .strength)
        persistenceController.create(exercise)
        
        let session = TestHelpers.createTestWorkoutSession(title: "Upper Day")
        persistenceController.create(session)
        
        let sessionExercise = SessionExercise(
            exercise: exercise,
            plannedSets: 3,
            plannedReps: 8,
            position: 1.0,
            session: session,
            autoPopulateFromLastSession: false
        )
        persistenceController.create(sessionExercise)
        
        // Weighted bodyweight exercises (additional weight, not total body weight)
        let sets = [
            (reps: 8, weight: 25.0),   // 25lb plate
            (reps: 6, weight: 35.0),   // 35lb plate
            (reps: 4, weight: 45.0)    // 45lb plate
        ]
        
        var expectedVolume = 0.0
        for (reps, weight) in sets {
            let set = CompletedSet(reps: reps, weight: weight, sessionExercise: sessionExercise)
            persistenceController.create(set)
            expectedVolume += Double(reps) * weight
        }
        
        // Refresh to get updated relationships
        let fetchedSessionExercise = persistenceController.fetch(SessionExercise.self).first { $0.id == sessionExercise.id }!
        
        // Expected: (8*25) + (6*35) + (4*45) = 200 + 210 + 180 = 590
        let wSet1 = 8.0 * 25.0
        let wSet2 = 6.0 * 35.0
        let wSet3 = 4.0 * 45.0
        let calculatedExpected = wSet1 + wSet2 + wSet3
        
        #expect(fetchedSessionExercise.totalVolume == expectedVolume)
        #expect(fetchedSessionExercise.totalVolume == calculatedExpected)
        
        print("✅ [WorkoutDomainTests.testWeightedBodyweightExerciseVolume] Test completed")
    }
    
    @Test("Mixed exercise types in single session")
    func testMixedExerciseTypesVolume() async throws {
        print("🔄 [WorkoutDomainTests.testMixedExerciseTypesVolume] Starting test")
        
        setUp()
        defer { tearDown() }
        
        // Create different types of exercises
        let weightedExercise = TestHelpers.createTestExercise(name: "Barbell Row")
        let bodyweightExercise = TestHelpers.createTestExercise(name: "Push-ups")
        let cardioExercise = TestHelpers.createTestExercise(name: "Burpees", category: .cardio)
        
        persistenceController.create(weightedExercise)
        persistenceController.create(bodyweightExercise)
        persistenceController.create(cardioExercise)
        
        let session = TestHelpers.createTestWorkoutSession(title: "Mixed Workout")
        persistenceController.create(session)
        
        // Weighted exercise
        let sessionExercise1 = SessionExercise(
            exercise: weightedExercise,
            plannedSets: 2,
            plannedReps: 10,
            position: 1.0,
            session: session,
            autoPopulateFromLastSession: false
        )
        persistenceController.create(sessionExercise1)
        
        let set1_1 = CompletedSet(reps: 10, weight: 115.0, sessionExercise: sessionExercise1)
        let set1_2 = CompletedSet(reps: 8, weight: 125.0, sessionExercise: sessionExercise1)
        persistenceController.create(set1_1)
        persistenceController.create(set1_2)
        
        // Bodyweight exercise (0 weight)
        let sessionExercise2 = SessionExercise(
            exercise: bodyweightExercise,
            plannedSets: 2,
            plannedReps: 15,
            position: 2.0,
            session: session,
            autoPopulateFromLastSession: false
        )
        persistenceController.create(sessionExercise2)
        
        let set2_1 = CompletedSet(reps: 15, weight: 0.0, sessionExercise: sessionExercise2)
        let set2_2 = CompletedSet(reps: 12, weight: 0.0, sessionExercise: sessionExercise2)
        persistenceController.create(set2_1)
        persistenceController.create(set2_2)
        
        // Cardio exercise (counted as volume with weight)
        let sessionExercise3 = SessionExercise(
            exercise: cardioExercise,
            plannedSets: 1,
            plannedReps: 20,
            position: 3.0,
            session: session,
            autoPopulateFromLastSession: false
        )
        persistenceController.create(sessionExercise3)
        
        let set3_1 = CompletedSet(reps: 20, weight: 0.0, sessionExercise: sessionExercise3)
        persistenceController.create(set3_1)
        
        // Refresh to get updated relationships
        let fetchedSession = persistenceController.fetch(WorkoutSession.self).first { $0.id == session.id }!
        
        // Calculate expected volumes
        let w1 = 10.0 * 115.0
        let w2 = 8.0 * 125.0
        let weightedVolume = w1 + w2  // 1150 + 1000 = 2150
        let b1 = 15.0 * 0.0
        let b2 = 12.0 * 0.0
        let bodyweightVolume = b1 + b2   // 0
        let cardioVolume = 20.0 * 0.0    // 0
        
        let expectedTotalVolume = weightedVolume + bodyweightVolume + cardioVolume
        
        #expect(fetchedSession.totalVolume == expectedTotalVolume)
        #expect(fetchedSession.totalVolume == 2150.0)
        
        print("✅ [WorkoutDomainTests.testMixedExerciseTypesVolume] Test completed")
    }
    
    @Test("Volume calculation mathematical correctness")
    func testVolumeCalculationMathematicalCorrectness() async throws {
        print("🔄 [WorkoutDomainTests.testVolumeCalculationMathematicalCorrectness] Starting test")
        
        setUp()
        defer { tearDown() }
        
        let exercise = TestHelpers.createTestExercise(name: "Math Test Exercise")
        persistenceController.create(exercise)
        
        let session = TestHelpers.createTestWorkoutSession(title: "Math Test Session")
        persistenceController.create(session)
        
        let sessionExercise = SessionExercise(
            exercise: exercise,
            plannedSets: 5,
            plannedReps: 10,
            position: 1.0,
            session: session,
            autoPopulateFromLastSession: false
        )
        persistenceController.create(sessionExercise)
        
        // Test various mathematical scenarios
        let sets = [
            (reps: 1, weight: 1.0),      // 1
            (reps: 0, weight: 100.0),    // 0 (no reps)
            (reps: 10, weight: 0.0),     // 0 (no weight)
            (reps: 5, weight: 2.5),      // 12.5 (decimal weight)
            (reps: 100, weight: 0.1)     // 10.0 (small weight, many reps)
        ]
        
        var manualCalculation = 0.0
        for (reps, weight) in sets {
            let set = CompletedSet(reps: reps, weight: weight, sessionExercise: sessionExercise)
            persistenceController.create(set)
            manualCalculation += Double(reps) * weight
        }
        
        // Refresh to get updated relationships
        let fetchedSessionExercise = persistenceController.fetch(SessionExercise.self).first { $0.id == sessionExercise.id }!
        
        // Expected: 1 + 0 + 0 + 12.5 + 10 = 23.5
        let mathVol1 = 1.0
        let mathVol2 = 0.0
        let mathVol3 = 0.0
        let mathVol4 = 12.5
        let mathVol5 = 10.0
        let expectedVolume = mathVol1 + mathVol2 + mathVol3 + mathVol4 + mathVol5
        
        #expect(fetchedSessionExercise.totalVolume == manualCalculation)
        #expect(fetchedSessionExercise.totalVolume == expectedVolume)
        #expect(fetchedSessionExercise.totalVolume == 23.5)
        
        print("✅ [WorkoutDomainTests.testVolumeCalculationMathematicalCorrectness] Test completed")
    }
    
    @Test("Empty session has zero volume")
    func testEmptySessionVolume() async throws {
        print("🔄 [WorkoutDomainTests.testEmptySessionVolume] Starting test")
        
        setUp()
        defer { tearDown() }
        
        let session = TestHelpers.createTestWorkoutSession(title: "Empty Session")
        persistenceController.create(session)
        
        // Session with no exercises should have zero volume
        #expect(session.totalVolume == 0.0)
        
        print("✅ [WorkoutDomainTests.testEmptySessionVolume] Test completed")
    }
    
    @Test("Session with exercises but no completed sets")
    func testSessionWithExercisesButNoSets() async throws {
        print("🔄 [WorkoutDomainTests.testSessionWithExercisesButNoSets] Starting test")
        
        setUp()
        defer { tearDown() }
        
        let exercise = TestHelpers.createTestExercise(name: "Planned But Not Done")
        persistenceController.create(exercise)
        
        let session = TestHelpers.createTestWorkoutSession(title: "Planned Session")
        persistenceController.create(session)
        
        // Add exercise to session but no completed sets
        let sessionExercise = SessionExercise(
            exercise: exercise,
            plannedSets: 3,
            plannedReps: 10,
            position: 1.0,
            session: session,
            autoPopulateFromLastSession: false
        )
        persistenceController.create(sessionExercise)
        
        // Refresh to get updated relationships
        let fetchedSession = persistenceController.fetch(WorkoutSession.self).first { $0.id == session.id }!
        let fetchedSessionExercise = persistenceController.fetch(SessionExercise.self).first { $0.id == sessionExercise.id }!
        
        // No completed sets means zero volume
        #expect(fetchedSessionExercise.totalVolume == 0.0)
        #expect(fetchedSession.totalVolume == 0.0)
        
        print("✅ [WorkoutDomainTests.testSessionWithExercisesButNoSets] Test completed")
    }
}