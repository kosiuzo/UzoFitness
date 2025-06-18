//
//  RelationshipIntegrityTests.swift
//  UzoFitnessTests
//
//  Ensures cascade-delete semantics stay intact.
//
import XCTest
import SwiftData
@testable import UzoFitness

@MainActor
final class RelationshipIntegrityTests: XCTestCase {
    private var db: PersistenceController!
    
    override func setUp() async throws {
        db = PersistenceController(inMemory: true)
    }
    
    func testCascadeDeleteSessionRemovesChildren() throws {
        // Build a tiny hierarchy
        let ex  = Exercise(name: "Row", category: .strength)
        db.create(ex)
        
        let ssn = WorkoutSession(date: .now)
        db.create(ssn)
        
        let sx = SessionExercise(exercise: ex,
                                 plannedSets: 1,
                                 plannedReps: 1,
                                 position: 1,
                                 session: ssn)
        db.create(sx)
        ssn.sessionExercises.append(sx)
        
        let set = CompletedSet(reps: 1, weight: 50, sessionExercise: sx)
        db.create(set)
        sx.completedSets.append(set)
        
        XCTAssertEqual(db.fetch(WorkoutSession.self).count, 1)
        XCTAssertEqual(db.fetch(SessionExercise.self).count, 1)
        XCTAssertEqual(db.fetch(CompletedSet.self).count, 1)
        
        // Delete root
        db.delete(ssn)
        
        XCTAssertTrue(db.fetch(WorkoutSession.self).isEmpty)
        XCTAssertTrue(db.fetch(SessionExercise.self).isEmpty)
        XCTAssertTrue(db.fetch(CompletedSet.self).isEmpty)
    }
}
