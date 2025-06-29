//
//  WorkoutDomainTests.swift
//  UzoFitnessTests
//
//  Verifies total-volume math and “happy-path” creation flows.
//
import XCTest
import SwiftData
@testable import UzoFitness   // ← your app module

@MainActor
final class WorkoutDomainTests: XCTestCase {
    private var db: PersistenceController!
    private var ctx: ModelContext!
    
    override func setUp() async throws {
        db  = PersistenceController(inMemory: true)
        ctx = db.context
    }
    
    // MARK: – totalVolume
    
    func testTotalVolumePerExerciseAndSession() throws {
        // GIVEN a body-weight push-up session …
        let pushUp = Exercise(name: "Push-up", category: .strength)
        db.create(pushUp)
        
        let session = WorkoutSession(date: .now)
        db.create(session)
        
        let sx = SessionExercise(
            exercise: pushUp,
            plannedSets: 2,
            plannedReps: 10,
            position: 1.0,
            session: session
        )
        db.create(sx)
        
        // Two completed sets (0 lb body-weight)
        db.create(CompletedSet(reps: 10, weight: 10, sessionExercise: sx))
        db.create(CompletedSet(reps: 12, weight: 10, sessionExercise: sx))
        
        // WHEN we refetch
        let freshSx = db.fetch(SessionExercise.self).first
        let freshSs = db.fetch(WorkoutSession.self).first
        
        // THEN both volumes are zero (0 × reps)
        XCTAssertEqual(freshSx?.totalVolume, 220)
        XCTAssertEqual(freshSs?.totalVolume, 220)
    }
    
    func testAddWeightedVolume() throws {
        // GIVEN 3 × 100 lb squats
        let squat = Exercise(name: "Squat", category: .strength)
        db.create(squat)
        
        let sesh = WorkoutSession(date: .now)
        db.create(sesh)
        
        let sx = SessionExercise(
            exercise: squat,
            plannedSets: 3,
            plannedReps: 5,
            plannedWeight: 100,
            position: 1.0,
            session: sesh
        )
        db.create(sx)
        
        sesh.sessionExercises.append(sx)
        
        let set1 = CompletedSet(reps: 5, weight: 100)
        let set2 = CompletedSet(reps: 5, weight: 100)
        let set3 = CompletedSet(reps: 5, weight: 100)

        db.create(set1)
        db.create(set2)
        db.create(set3)

        set1.sessionExercise = sx
        set2.sessionExercise = sx
        set3.sessionExercise = sx

        sx.completedSets.append(contentsOf: [set1, set2, set3])
        
        db.save()
        
        let volume = 3 * 5 * 100
        XCTAssertEqual(sx.totalVolume, Double(volume))
        XCTAssertEqual(sesh.totalVolume, Double(volume))
    }
}
