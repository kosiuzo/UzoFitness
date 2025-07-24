import Foundation
import SwiftData
import Testing
import UzoFitnessCore
@testable import UzoFitness

// MARK: - Data Persistence Integration Tests

/// Tests for data persistence integration with SwiftData and all model types
@MainActor
final class DataPersistenceIntegrationTests {
    
    // MARK: - Test Properties
    private var persistenceController: PersistenceController!
    
    // MARK: - Setup and Teardown
    
    private func setUp() {
        persistenceController = PersistenceController(inMemory: true)
    }
    
    private func tearDown() {
        // Clean up test data
        persistenceController?.deleteAllData()
        persistenceController = nil
    }
    
    // MARK: - Model Type Persistence Tests
    
    @Test("Exercise model persistence operations")
    func testExercisePersistence() {
        setUp()
        defer { tearDown() }
        
        // Create test exercise
        let exercise = Exercise(
            name: "Test Push-up",
            category: .strength,
            instructions: "A test push-up exercise"
        )
        
        // Test insert
        persistenceController.create(exercise)
        
        // Test fetch
        let fetchedExercises = persistenceController.fetch(Exercise.self)
        #expect(fetchedExercises.count == 1)
        #expect(fetchedExercises.first?.name == "Test Push-up")
        #expect(fetchedExercises.first?.category == .strength)
        
        // Test update
        exercise.name = "Updated Push-up"
        persistenceController.save()
        
        let updatedExercises = persistenceController.fetch(Exercise.self)
        #expect(updatedExercises.first?.name == "Updated Push-up")
        
        // Test delete
        persistenceController.delete(exercise)
        let deletedCheck = persistenceController.fetch(Exercise.self)
        #expect(deletedCheck.isEmpty)
    }
    
    @Test("WorkoutTemplate model persistence operations")
    func testWorkoutTemplatePersistence() {
        setUp()
        defer { tearDown() }
        
        // Create test workout template
        let template = WorkoutTemplate(
            name: "Test Template",
            summary: "A test workout template"
        )
        
        // Test insert
        persistenceController.create(template)
        
        // Test fetch
        let fetchedTemplates = persistenceController.fetch(WorkoutTemplate.self)
        #expect(fetchedTemplates.count == 1)
        #expect(fetchedTemplates.first?.name == "Test Template")
        #expect(fetchedTemplates.first?.summary == "A test workout template")
        
        // Test delete
        persistenceController.delete(template)
        let deletedCheck = persistenceController.fetch(WorkoutTemplate.self)
        #expect(deletedCheck.isEmpty)
    }
    
    @Test("WorkoutSession model persistence operations")
    func testWorkoutSessionPersistence() {
        setUp()
        defer { tearDown() }
        
        // Create dependencies
        let template = WorkoutTemplate(name: "Test Template", summary: "Test")
        let plan = WorkoutPlan(customName: "Test Plan", template: template)
        persistenceController.create(template)
        persistenceController.create(plan)
        
        // Create test workout session
        let session = WorkoutSession(
            date: Date(),
            title: "Test Session",
            plan: plan
        )
        
        // Test insert
        persistenceController.create(session)
        
        // Test fetch
        let fetchedSessions = persistenceController.fetch(WorkoutSession.self)
        #expect(fetchedSessions.count == 1)
        #expect(fetchedSessions.first?.title == "Test Session")
        #expect(fetchedSessions.first?.plan?.customName == "Test Plan")
        
        // Test delete
        persistenceController.delete(session)
        let deletedCheck = persistenceController.fetch(WorkoutSession.self)
        #expect(deletedCheck.isEmpty)
    }
    
    @Test("ProgressPhoto model persistence operations")
    func testProgressPhotoPersistence() {
        setUp()
        defer { tearDown() }
        
        // Create test progress photo
        let photo = ProgressPhoto(
            date: Date(),
            angle: .front,
            assetIdentifier: "test-asset-identifier"
        )
        
        // Test insert
        persistenceController.create(photo)
        
        // Test fetch
        let fetchedPhotos = persistenceController.fetch(ProgressPhoto.self)
        #expect(fetchedPhotos.count == 1)
        #expect(fetchedPhotos.first?.assetIdentifier == "test-asset-identifier")
        #expect(fetchedPhotos.first?.angle == .front)
        
        // Test delete
        persistenceController.delete(photo)
        let deletedCheck = persistenceController.fetch(ProgressPhoto.self)
        #expect(deletedCheck.isEmpty)
    }
    
    // MARK: - Relationship Persistence Tests
    
    @Test("WorkoutTemplate cascade relationships persist correctly")
    func testWorkoutTemplateRelationshipPersistence() {
        setUp()
        defer { tearDown() }
        
        // Create exercise
        let exercise = Exercise(name: "Test Exercise", category: .strength, instructions: "Test")
        persistenceController.create(exercise)
        
        // Create template with day and exercise templates
        let template = WorkoutTemplate(name: "Test Template", summary: "Test")
        persistenceController.create(template)
        
        let dayTemplate = DayTemplate(weekday: .monday, notes: "Test day")
        dayTemplate.workoutTemplate = template
        persistenceController.create(dayTemplate)
        (dayTemplate)
        
        let exerciseTemplate = ExerciseTemplate(
            exercise: exercise,
            setCount: 3,
            reps: 10,
            position: 1.0
        )
        exerciseTemplate.dayTemplate = dayTemplate
        persistenceController.create(exerciseTemplate)
        (exerciseTemplate)
        
        // Verify relationships
        let fetchedTemplates = persistenceController.fetch(WorkoutTemplate.self)
        #expect(fetchedTemplates.count == 1)
        #expect(fetchedTemplates.first?.dayTemplates.count == 1)
        #expect(fetchedTemplates.first?.dayTemplates.first?.exerciseTemplates.count == 1)
        #expect(fetchedTemplates.first?.dayTemplates.first?.exerciseTemplates.first?.setCount == 3)
        
        // Test cascade delete
        persistenceController.delete(template)
        
        // Verify cascade deletion
        let templatesCheck = persistenceController.fetch(WorkoutTemplate.self)
        let dayTemplatesCheck = persistenceController.fetch(DayTemplate.self)
        let exerciseTemplatesCheck = persistenceController.fetch(ExerciseTemplate.self)
        
        #expect(templatesCheck.isEmpty)
        #expect(dayTemplatesCheck.isEmpty)
        #expect(exerciseTemplatesCheck.isEmpty)
        
        // Exercise should still exist (not cascade deleted)
        let exercisesCheck = persistenceController.fetch(Exercise.self)
        #expect(exercisesCheck.count == 1)
    }
    
    @Test("WorkoutSession cascade relationships persist correctly")
    func testWorkoutSessionRelationshipPersistence() {
        setUp()
        defer { tearDown() }
        
        // Create dependencies
        let exercise = Exercise(name: "Test Exercise", category: .strength, instructions: "Test")
        let template = WorkoutTemplate(name: "Test Template", summary: "Test")
        let plan = WorkoutPlan(customName: "Test Plan", template: template)
        
        persistenceController.create(exercise)
        persistenceController.create(template)
        persistenceController.create(plan)
        
        // Create session with session exercise and completed sets
        let session = WorkoutSession(date: Date(), title: "Test Session", plan: plan)
        persistenceController.create(session)
        
        let sessionExercise = SessionExercise(
            exercise: exercise,
            plannedSets: 3,
            plannedReps: 10,
            plannedWeight: 0.0,
            position: 1.0
        )
        sessionExercise.session = session
        persistenceController.create(sessionExercise)
        (sessionExercise)
        
        let completedSet1 = CompletedSet(reps: 10, weight: 0)
        let completedSet2 = CompletedSet(reps: 8, weight: 0)
        completedSet1.sessionExercise = sessionExercise
        completedSet2.sessionExercise = sessionExercise
        persistenceController.create(completedSet1)
        persistenceController.create(completedSet2)
        
        // Verify relationships
        let fetchedSessions = persistenceController.fetch(WorkoutSession.self)
        #expect(fetchedSessions.count == 1)
        #expect(fetchedSessions.first?.sessionExercises.count == 1)
        #expect(fetchedSessions.first?.sessionExercises.first?.completedSets.count == 2)
        
        // Test volume calculation
        let totalVolume = fetchedSessions.first?.totalVolume ?? 0
        #expect(totalVolume == 0) // Body weight exercise should have 0 volume
        
        // Test cascade delete
        persistenceController.delete(session)
        
        // Verify cascade deletion
        let sessionsCheck = persistenceController.fetch(WorkoutSession.self)
        let sessionExercisesCheck = persistenceController.fetch(SessionExercise.self)
        let completedSetsCheck = persistenceController.fetch(CompletedSet.self)
        
        #expect(sessionsCheck.isEmpty)
        #expect(sessionExercisesCheck.isEmpty)
        #expect(completedSetsCheck.isEmpty)
        
        // Exercise should still exist (not cascade deleted)
        let exercisesCheck = persistenceController.fetch(Exercise.self)
        #expect(exercisesCheck.count == 1)
    }
    
    // MARK: - Query and Predicate Tests
    
    @Test("Predicate-based queries work correctly")
    func testPredicateQueries() {
        setUp()
        defer { tearDown() }
        
        // Create test exercises with different categories
        let strengthExercise = Exercise(name: "Push-up", category: .strength, instructions: "Strength exercise")
        let cardioExercise = Exercise(name: "Running", category: .cardio, instructions: "Cardio exercise")
        let mobilityExercise = Exercise(name: "Stretch", category: .mobility, instructions: "Mobility exercise")
        
        persistenceController.create(strengthExercise)
        persistenceController.create(cardioExercise)
        persistenceController.create(mobilityExercise)
        
        // Test category-based query
        let strengthExercises = persistenceController.getExercises(by: .strength)
        #expect(strengthExercises.count == 1)
        #expect(strengthExercises.first?.name == "Push-up")
        
        let cardioExercises = persistenceController.getExercises(by: .cardio)
        #expect(cardioExercises.count == 1)
        #expect(cardioExercises.first?.name == "Running")
        
        // Test angle-based progress photo query
        let frontPhoto = ProgressPhoto(date: Date(), angle: .front, assetIdentifier: "front-asset")
        let sidePhoto = ProgressPhoto(date: Date(), angle: .side, assetIdentifier: "side-asset")
        
        persistenceController.create(frontPhoto)
        persistenceController.create(sidePhoto)
        
        let frontPhotos = persistenceController.getProgressPhotos(for: .front)
        #expect(frontPhotos.count == 1)
        #expect(frontPhotos.first?.assetIdentifier == "front-asset")
        
        let sidePhotos = persistenceController.getProgressPhotos(for: .side)
        #expect(sidePhotos.count == 1)
        #expect(sidePhotos.first?.assetIdentifier == "side-asset")
    }
    
    @Test("Date range queries work correctly")
    func testDateRangeQueries() {
        setUp()
        defer { tearDown() }
        
        // Create test data with different dates
        let template = WorkoutTemplate(name: "Test Template", summary: "Test")
        let plan = WorkoutPlan(customName: "Test Plan", template: template)
        persistenceController.create(template)
        persistenceController.create(plan)
        
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        
        let session1 = WorkoutSession(date: today, title: "Today Session", plan: plan)
        let session2 = WorkoutSession(date: yesterday, title: "Yesterday Session", plan: plan)
        let session3 = WorkoutSession(date: twoDaysAgo, title: "Two Days Ago Session", plan: plan)
        
        persistenceController.create(session1)
        persistenceController.create(session2)
        persistenceController.create(session3)
        
        // Test date range query (yesterday to today)
        let startOfYesterday = calendar.startOfDay(for: yesterday)
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: today))!
        
        let sessionsInRange = persistenceController.getWorkoutSessions(from: startOfYesterday, to: endOfToday)
        #expect(sessionsInRange.count == 2)
        
        // Verify they are sorted by date (reverse chronological)
        #expect(sessionsInRange.first?.title == "Today Session")
        #expect(sessionsInRange.last?.title == "Yesterday Session")
        
        // Test recent sessions query
        let recentSessions = persistenceController.getRecentWorkoutSessions(limit: 2)
        #expect(recentSessions.count == 2)
        #expect(recentSessions.first?.title == "Today Session")
        #expect(recentSessions.last?.title == "Yesterday Session")
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Data persistence handles concurrent operations correctly")
    func testConcurrentOperations() async {
        setUp()
        defer { tearDown() }
        
        // Create multiple exercises concurrently
        await withTaskGroup(of: Void.self) { group in
            for i in 1...5 {
                group.addTask { [self] in
                    await MainActor.run {
                        let exercise = Exercise(
                            name: "Exercise \(i)",
                            category: .strength,
                            instructions: "Test exercise \(i)"
                        )
                        self.persistenceController.create(exercise)
                    }
                }
            }
        }
        
        // Verify all exercises were created
        let exercises = persistenceController.fetch(Exercise.self)
        #expect(exercises.count == 5)
        
        // Verify all names are unique
        let exerciseNames = Set(exercises.map { $0.name })
        #expect(exerciseNames.count == 5)
    }
    
    @Test("Batch operations work correctly")
    func testBatchOperations() {
        setUp()
        defer { tearDown() }
        
        // Create multiple exercises
        var exercises: [Exercise] = []
        for i in 1...10 {
            let exercise = Exercise(
                name: "Exercise \(i)",
                category: .strength,
                instructions: "Test exercise \(i)"
            )
            exercises.append(exercise)
            persistenceController.create(exercise)
        }
        
        // Verify all created
        let fetchedExercises = persistenceController.fetch(Exercise.self)
        #expect(fetchedExercises.count == 10)
        
        // Test batch deletion
        persistenceController.delete(exercises)
        
        // Verify all deleted
        let deletedCheck = persistenceController.fetch(Exercise.self)
        #expect(deletedCheck.isEmpty)
    }
    
    @Test("deleteAllData removes all model types")
    func testDeleteAllData() {
        setUp()
        defer { tearDown() }
        
        // Create instances of all model types
        let exercise = Exercise(name: "Test Exercise", category: .strength, instructions: "Test")
        let template = WorkoutTemplate(name: "Test Template", summary: "Test")
        let dayTemplate = DayTemplate(weekday: .monday, notes: "Test")
        let exerciseTemplate = ExerciseTemplate(exercise: exercise, setCount: 3, reps: 10, position: 1.0)
        let plan = WorkoutPlan(customName: "Test Plan", template: template)
        let session = WorkoutSession(date: Date(), title: "Test Session", plan: plan)
        let sessionExercise = SessionExercise(exercise: exercise, plannedSets: 3, plannedReps: 10, plannedWeight: 0.0, position: 1.0)
        let completedSet = CompletedSet(reps: 10, weight: 0)
        let photo = ProgressPhoto(date: Date(), angle: .front, assetIdentifier: "test-asset")
        let performedExercise = PerformedExercise(reps: 10, weight: 0.0, exercise: exercise)
        
        // Set up relationships
        dayTemplate.workoutTemplate = template
        exerciseTemplate.dayTemplate = dayTemplate
        sessionExercise.session = session
        completedSet.sessionExercise = sessionExercise
        
        // Create all models
        let allModels: [any PersistentModel] = [
            exercise, template, dayTemplate, exerciseTemplate, plan,
            session, sessionExercise, completedSet, photo, performedExercise
        ]
        
        allModels.forEach { model in
            persistenceController.context.insert(model)
        }
        persistenceController.save()
        
        // Verify all models exist
        #expect(persistenceController.fetch(Exercise.self).count == 1)
        #expect(persistenceController.fetch(WorkoutTemplate.self).count == 1)
        #expect(persistenceController.fetch(DayTemplate.self).count == 1)
        #expect(persistenceController.fetch(ExerciseTemplate.self).count == 1)
        #expect(persistenceController.fetch(WorkoutPlan.self).count == 1)
        #expect(persistenceController.fetch(WorkoutSession.self).count == 1)
        #expect(persistenceController.fetch(SessionExercise.self).count == 1)
        #expect(persistenceController.fetch(CompletedSet.self).count == 1)
        #expect(persistenceController.fetch(ProgressPhoto.self).count == 1)
        #expect(persistenceController.fetch(PerformedExercise.self).count == 1)
        
        // Test deleteAllData
        persistenceController.deleteAllData()
        
        // Verify all models are deleted
        #expect(persistenceController.fetch(Exercise.self).isEmpty)
        #expect(persistenceController.fetch(WorkoutTemplate.self).isEmpty)
        #expect(persistenceController.fetch(DayTemplate.self).isEmpty)
        #expect(persistenceController.fetch(ExerciseTemplate.self).isEmpty)
        #expect(persistenceController.fetch(WorkoutPlan.self).isEmpty)
        #expect(persistenceController.fetch(WorkoutSession.self).isEmpty)
        #expect(persistenceController.fetch(SessionExercise.self).isEmpty)
        #expect(persistenceController.fetch(CompletedSet.self).isEmpty)
        #expect(persistenceController.fetch(ProgressPhoto.self).isEmpty)
        #expect(persistenceController.fetch(PerformedExercise.self).isEmpty)
    }
}