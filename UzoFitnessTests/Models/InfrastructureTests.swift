import Foundation
import SwiftData
import Testing
import UzoFitnessCore
@testable import UzoFitness

/// Infrastructure tests to verify the test setup works correctly
@MainActor
final class InfrastructureTests {
    
    // MARK: - Test Properties
    private var persistenceController: InMemoryPersistenceController!
    
    // MARK: - Test Setup and Teardown
    
    @Test("In-memory persistence controller initialization")
    func testInMemoryPersistenceControllerInitialization() async throws {
        print("🔄 [InfrastructureTests.testInMemoryPersistenceControllerInitialization] Starting test")
        
        persistenceController = InMemoryPersistenceController()
        
        // Verify the controller was created
        #expect(persistenceController != nil)
        
        // Verify it's using in-memory storage
        let exercises = persistenceController.fetch(Exercise.self)
        #expect(exercises.isEmpty)
        
        print("✅ [InfrastructureTests.testInMemoryPersistenceControllerInitialization] Test completed")
    }
    
    @Test("Test data setup and cleanup")
    func testTestDataSetupAndCleanup() async throws {
        print("🔄 [InfrastructureTests.testTestDataSetupAndCleanup] Starting test")
        
        persistenceController = InMemoryPersistenceController()
        
        // Verify initial state is empty
        let initialExercises = persistenceController.fetch(Exercise.self)
        #expect(initialExercises.isEmpty)
        
        // Setup test data
        persistenceController.setupTestData()
        
        // Verify test data was created
        let exercisesAfterSetup = persistenceController.fetch(Exercise.self)
        #expect(!exercisesAfterSetup.isEmpty)
        
        // Cleanup test data
        persistenceController.cleanupTestData()
        
        // Verify cleanup worked
        let exercisesAfterCleanup = persistenceController.fetch(Exercise.self)
        #expect(exercisesAfterCleanup.isEmpty)
        
        print("✅ [InfrastructureTests.testTestDataSetupAndCleanup] Test completed")
    }
    
    @Test("All model types can be inserted and fetched")
    func testAllModelTypesCanBeInsertedAndFetched() async throws {
        print("🔄 [InfrastructureTests.testAllModelTypesCanBeInsertedAndFetched] Starting test")
        
        persistenceController = InMemoryPersistenceController()
        
        // Verify all model types work
        let allTypesVerified = persistenceController.verifyAllModelTypes()
        #expect(allTypesVerified)
        
        print("✅ [InfrastructureTests.testAllModelTypesCanBeInsertedAndFetched] Test completed")
    }
    
    @Test("Test helpers create valid test data")
    func testTestHelpersCreateValidTestData() async throws {
        print("🔄 [InfrastructureTests.testTestHelpersCreateValidTestData] Starting test")
        
        persistenceController = InMemoryPersistenceController()
        
        // Test exercise creation
        let exercise = TestHelpers.createTestExercise(
            name: "Test Exercise",
            category: .strength,
            instructions: "Test instructions"
        )
        persistenceController.create(exercise)
        
        let fetchedExercise = persistenceController.fetch(Exercise.self).first
        #expect(fetchedExercise != nil)
        #expect(fetchedExercise?.name == "Test Exercise")
        #expect(fetchedExercise?.category == .strength)
        
        // Test workout template creation
        let template = TestHelpers.createTestWorkoutTemplate(
            name: "Test Template",
            summary: "Test summary"
        )
        persistenceController.create(template)
        
        let fetchedTemplate = persistenceController.fetch(WorkoutTemplate.self).first
        #expect(fetchedTemplate != nil)
        #expect(fetchedTemplate?.name == "Test Template")
        
        // Test workout session creation
        let session = TestHelpers.createTestWorkoutSession(
            title: "Test Session"
        )
        persistenceController.create(session)
        
        let fetchedSession = persistenceController.fetch(WorkoutSession.self).first
        #expect(fetchedSession != nil)
        #expect(fetchedSession?.title == "Test Session")
        
        print("✅ [InfrastructureTests.testTestHelpersCreateValidTestData] Test completed")
    }
    
    @Test("Test data factories create realistic data")
    func testTestDataFactoriesCreateRealisticData() async throws {
        print("🔄 [InfrastructureTests.testTestDataFactoriesCreateRealisticData] Starting test")
        
        persistenceController = InMemoryPersistenceController()
        
        // Test common exercises creation
        let commonExercises = TestDataFactories.createCommonExercises()
        #expect(commonExercises.count > 0)
        
        // Verify exercise properties
        let pushup = commonExercises.first { $0.name == "Push-up" }
        #expect(pushup != nil)
        #expect(pushup?.category == .strength)
        
        let burpee = commonExercises.first { $0.name == "Burpee" }
        #expect(burpee != nil)
        #expect(burpee?.category == .cardio)
        
        // Test common workout templates creation
        let commonTemplates = TestDataFactories.createCommonWorkoutTemplates()
        #expect(commonTemplates.count > 0)
        
        // Verify template properties
        let upperBodyTemplate = commonTemplates.first { $0.name == "Upper Body Blast" }
        #expect(upperBodyTemplate != nil)
        #expect(upperBodyTemplate?.summary.contains("chest") == true)
        
        print("✅ [InfrastructureTests.testTestDataFactoriesCreateRealisticData] Test completed")
    }
    
    @Test("Complete workout setup creates all related entities")
    func testCompleteWorkoutSetupCreatesAllRelatedEntities() async throws {
        print("🔄 [InfrastructureTests.testCompleteWorkoutSetupCreatesAllRelatedEntities] Starting test")
        
        persistenceController = InMemoryPersistenceController()
        
        // Create complete workout setup
        let (exercise, template, dayTemplate, exerciseTemplate, plan, session, sessionExercise, completedSet) = 
            TestDataFactories.createCompleteWorkoutSetup(persistenceController: persistenceController)
        
        // Verify all entities were created
        #expect(TestHelpers.validateModelPersisted(exercise, in: persistenceController))
        #expect(TestHelpers.validateModelPersisted(template, in: persistenceController))
        #expect(TestHelpers.validateModelPersisted(dayTemplate, in: persistenceController))
        #expect(TestHelpers.validateModelPersisted(exerciseTemplate, in: persistenceController))
        #expect(TestHelpers.validateModelPersisted(plan, in: persistenceController))
        #expect(TestHelpers.validateModelPersisted(session, in: persistenceController))
        #expect(TestHelpers.validateModelPersisted(sessionExercise, in: persistenceController))
        #expect(TestHelpers.validateModelPersisted(completedSet, in: persistenceController))
        
        // Verify relationships
        #expect(dayTemplate.workoutTemplate?.id == template.id)
        #expect(exerciseTemplate.dayTemplate?.id == dayTemplate.id)
        #expect(session.plan?.id == plan.id)
        #expect(sessionExercise.session?.id == session.id)
        #expect(completedSet.sessionExercise?.id == sessionExercise.id)
        
        print("✅ [InfrastructureTests.testCompleteWorkoutSetupCreatesAllRelatedEntities] Test completed")
    }
    
    @Test("Async/await support works correctly")
    func testAsyncAwaitSupportWorksCorrectly() async throws {
        print("🔄 [InfrastructureTests.testAsyncAwaitSupportWorksCorrectly] Starting test")
        
        // Test wait function
        let startTime = Date()
        await TestHelpers.wait(seconds: 0.1)
        let endTime = Date()
        
        #expect(endTime.timeIntervalSince(startTime) >= 0.1)
        
        // Test waitForCondition function
        var conditionMet = false
        Task {
            await TestHelpers.wait(seconds: 0.1)
            conditionMet = true
        }
        
        let conditionResult = await TestHelpers.waitForCondition(
            timeout: 1.0,
            condition: { conditionMet }
        )
        
        #expect(conditionResult)
        
        print("✅ [InfrastructureTests.testAsyncAwaitSupportWorksCorrectly] Test completed")
    }
    
    @Test("Large dataset creation works correctly")
    func testLargeDatasetCreationWorksCorrectly() async throws {
        print("🔄 [InfrastructureTests.testLargeDatasetCreationWorksCorrectly] Starting test")
        
        persistenceController = InMemoryPersistenceController()
        
        // Create a small dataset for testing
        TestHelpers.createLargeDataset(
            exerciseCount: 10,
            sessionCount: 5,
            in: persistenceController
        )
        
        // Verify data was created
        let exercises = persistenceController.fetch(Exercise.self)
        let sessions = persistenceController.fetch(WorkoutSession.self)
        let sessionExercises = persistenceController.fetch(SessionExercise.self)
        let completedSets = persistenceController.fetch(CompletedSet.self)
        
        #expect(exercises.count >= 10)
        #expect(sessions.count >= 5)
        #expect(sessionExercises.count > 0)
        #expect(completedSets.count > 0)
        
        print("✅ [InfrastructureTests.testLargeDatasetCreationWorksCorrectly] Test completed")
    }
    
    @Test("Test data cleanup works correctly")
    func testTestDataCleanupWorksCorrectly() async throws {
        print("🔄 [InfrastructureTests.testTestDataCleanupWorksCorrectly] Starting test")
        
        persistenceController = InMemoryPersistenceController()
        
        // Create some test data
        let exercise = TestHelpers.createTestExercise()
        persistenceController.create(exercise)
        
        let template = TestHelpers.createTestWorkoutTemplate()
        persistenceController.create(template)
        
        // Verify data exists
        #expect(!persistenceController.fetch(Exercise.self).isEmpty)
        #expect(!persistenceController.fetch(WorkoutTemplate.self).isEmpty)
        
        // Clean up data
        TestHelpers.cleanupTestData(in: persistenceController)
        
        // Verify data was cleaned up
        #expect(persistenceController.fetch(Exercise.self).isEmpty)
        #expect(persistenceController.fetch(WorkoutTemplate.self).isEmpty)
        
        print("✅ [InfrastructureTests.testTestDataCleanupWorksCorrectly] Test completed")
    }
} 