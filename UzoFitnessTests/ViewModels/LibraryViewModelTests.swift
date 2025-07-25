import XCTest
import SwiftData
import UzoFitnessCore
@testable import UzoFitness

@MainActor
class LibraryViewModelTests: XCTestCase {
    
    // MARK: - Test Properties
    private var persistenceController: InMemoryPersistenceController!
    private var viewModel: LibraryViewModel!
    
    // MARK: - Setup and Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory persistence controller
        persistenceController = InMemoryPersistenceController()
        
        // Create view model with test context
        viewModel = LibraryViewModel(modelContext: persistenceController.context)
        
        // Wait for initial data load
        await TestHelpers.wait(seconds: 0.1)
    }
    
    override func tearDown() async throws {
        // Clean up test data
        persistenceController.cleanupTestData()
        viewModel = nil
        persistenceController = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization_SetsDefaultState() {
        // Given: A newly initialized LibraryViewModel
        // (viewModel created in setUp)
        
        // Then: Default state should be set correctly
        XCTAssertEqual(viewModel.state, .loaded, "Initial state should be loaded after initialization")
        XCTAssertEqual(viewModel.selectedSegment, .workouts, "Default segment should be workouts")
        XCTAssertFalse(viewModel.showTemplateSheet, "Template sheet should not be shown initially")
        XCTAssertFalse(viewModel.showExerciseSheet, "Exercise sheet should not be shown initially")
        XCTAssertNil(viewModel.error, "No error should be present initially")
        XCTAssertNil(viewModel.activePlanID, "No active plan should be set initially")
        XCTAssertNil(viewModel.importErrorMessage, "No import error message should be present initially")
    }
    
    func testInitialization_LoadsTemplatesAndExercises() {
        // Given: A newly initialized LibraryViewModel with test data
        // When: Adding test data to persistence controller
        let testExercise = TestHelpers.createTestExercise(name: "Test Exercise")
        let testTemplate = TestHelpers.createTestWorkoutTemplate(name: "Test Template")
        
        persistenceController.create(testExercise)
        persistenceController.create(testTemplate)
        
        // Create a new view model to trigger fresh data load
        let newViewModel = LibraryViewModel(modelContext: persistenceController.context)
        
        // Then: Data should be loaded
        XCTAssertGreaterThan(newViewModel.exerciseCatalog.count, 0, "Exercises should be loaded")
        XCTAssertGreaterThan(newViewModel.templates.count, 0, "Templates should be loaded")
        XCTAssertEqual(newViewModel.state, .loaded, "State should be loaded")
    }
    
    func testInitialization_ComputedPropertiesWork() {
        // Given: A LibraryViewModel with test data
        let testExercise1 = TestHelpers.createTestExercise(name: "Zebra Exercise")
        let testExercise2 = TestHelpers.createTestExercise(name: "Alpha Exercise")
        let testTemplate1 = TestHelpers.createTestWorkoutTemplate(name: "New Template")
        let testTemplate2 = TestHelpers.createTestWorkoutTemplate(name: "Old Template")
        
        // Set creation dates to test sorting
        testTemplate1.createdAt = Date()
        testTemplate2.createdAt = Date().addingTimeInterval(-86400) // Yesterday
        
        persistenceController.create(testExercise1)
        persistenceController.create(testExercise2)
        persistenceController.create(testTemplate1)
        persistenceController.create(testTemplate2)
        
        // Create new view model to load data
        let newViewModel = LibraryViewModel(modelContext: persistenceController.context)
        
        // Then: Computed properties should work correctly
        XCTAssertTrue(newViewModel.canCreateTemplate, "Should always allow template creation")
        
        // Exercises should be sorted alphabetically
        let sortedExercises = newViewModel.sortedExercises
        XCTAssertEqual(sortedExercises.first?.name, "Alpha Exercise", "Exercises should be sorted alphabetically")
        
        // Templates should be sorted by creation date (newest first)
        let sortedTemplates = newViewModel.sortedTemplates
        XCTAssertEqual(sortedTemplates.first?.name, "New Template", "Templates should be sorted by creation date (newest first)")
        
        // Convenience properties should match sorted versions
        XCTAssertEqual(newViewModel.exercises.count, newViewModel.sortedExercises.count, "exercises property should match sortedExercises")
        XCTAssertEqual(newViewModel.workoutTemplates.count, newViewModel.sortedTemplates.count, "workoutTemplates property should match sortedTemplates")
    }
    
    func testInitialization_DependencyInjection() {
        // Given: A custom model context
        let customPersistenceController = InMemoryPersistenceController()
        
        // When: Creating a view model with the custom context
        let customViewModel = LibraryViewModel(modelContext: customPersistenceController.context)
        
        // Then: The view model should use the injected context
        XCTAssertEqual(customViewModel.state, .loaded, "View model should initialize successfully with injected context")
        XCTAssertNotNil(customViewModel, "View model should be created successfully")
    }
    
    func testInitialization_StateConsistency() {
        // Given: A newly initialized LibraryViewModel
        // (viewModel created in setUp)
        
        // Then: All state properties should be consistent
        XCTAssertEqual(viewModel.templates.count, viewModel.workoutTemplates.count, "templates and workoutTemplates should have same count")
        XCTAssertEqual(viewModel.exerciseCatalog.count, viewModel.exercises.count, "exerciseCatalog and exercises should have same count")
        XCTAssertEqual(viewModel.workoutPlans.count, 0, "No workout plans should exist initially")
        
        // Computed properties should not crash
        let _ = viewModel.activePlan // Should not crash even if nil
        let _ = viewModel.canCreateTemplate // Should return true
        let _ = viewModel.sortedTemplates // Should not crash
        let _ = viewModel.sortedExercises // Should not crash
    }
    
    func testInitialization_HandlesEmptyState() {
        // Given: An empty persistence controller
        let emptyPersistenceController = InMemoryPersistenceController()
        // Don't add any test data
        
        // When: Creating a view model with empty data
        let emptyViewModel = LibraryViewModel(modelContext: emptyPersistenceController.context)
        
        // Then: The view model should handle empty state gracefully
        XCTAssertEqual(emptyViewModel.templates.count, 0, "Templates should be empty")
        XCTAssertEqual(emptyViewModel.exerciseCatalog.count, 0, "Exercise catalog should be empty")
        XCTAssertEqual(emptyViewModel.workoutPlans.count, 0, "Workout plans should be empty")
        XCTAssertEqual(emptyViewModel.state, .loaded, "State should still be loaded")
        XCTAssertNil(emptyViewModel.error, "No error should occur with empty data")
        XCTAssertNil(emptyViewModel.activePlanID, "No active plan should exist")
    }
    
    func testInitialization_LoadsActivePlan() {
        // Given: A persistence controller with an active plan
        let testTemplate = TestHelpers.createTestWorkoutTemplate(name: "Active Template")
        let testPlan = TestHelpers.createTestWorkoutPlan(customName: "Active Plan", template: testTemplate)
        testPlan.isActive = true
        
        persistenceController.create(testTemplate)
        persistenceController.create(testPlan)
        
        // When: Creating a new view model
        let newViewModel = LibraryViewModel(modelContext: persistenceController.context)
        
        // Then: The active plan should be loaded
        XCTAssertEqual(newViewModel.activePlanID, testPlan.id, "Active plan ID should be set")
        XCTAssertNotNil(newViewModel.activePlan, "Active plan should be accessible")
        XCTAssertEqual(newViewModel.activePlan?.customName, "Active Plan", "Active plan name should match")
    }
    
    func testInitialization_LoadsWorkoutPlans() {
        // Given: A persistence controller with multiple workout plans
        let testTemplate = TestHelpers.createTestWorkoutTemplate(name: "Test Template")
        let testPlan1 = TestHelpers.createTestWorkoutPlan(customName: "Plan 1", template: testTemplate)
        let testPlan2 = TestHelpers.createTestWorkoutPlan(customName: "Plan 2", template: testTemplate)
        
        // Set different creation dates
        testPlan1.createdAt = Date()
        testPlan2.createdAt = Date().addingTimeInterval(-86400)
        
        persistenceController.create(testTemplate)
        persistenceController.create(testPlan1)
        persistenceController.create(testPlan2)
        
        // When: Creating a new view model
        let newViewModel = LibraryViewModel(modelContext: persistenceController.context)
        
        // Then: Workout plans should be loaded and sorted
        XCTAssertEqual(newViewModel.workoutPlans.count, 2, "Should load all workout plans")
        XCTAssertEqual(newViewModel.workoutPlans.first?.customName, "Plan 1", "Plans should be sorted by creation date (newest first)")
    }
    
    // MARK: - Template Management Tests
    
    func testCreateTemplate_ValidData_CreatesTemplate() {
        // Given: A view model and valid template data
        let initialTemplateCount = viewModel.templates.count
        let templateName = "New Workout Template"
        let templateSummary = "A great workout template"
        
        // When: Creating a template with valid data
        viewModel.handleIntent(.createTemplate(name: templateName, summary: templateSummary))
        
        // Then: Template should be created and added to the collection
        XCTAssertEqual(viewModel.templates.count, initialTemplateCount + 1, "Template count should increase by 1")
        XCTAssertTrue(viewModel.templates.contains { $0.name == templateName }, "Template should be added to collection")
        XCTAssertTrue(viewModel.showTemplateSheet, "Template sheet should be shown after creation")
        XCTAssertNil(viewModel.error, "No error should occur with valid data")
        
        // Verify the template was persisted
        let persistedTemplates = persistenceController.fetch(WorkoutTemplate.self)
        XCTAssertTrue(persistedTemplates.contains { $0.name == templateName }, "Template should be persisted")
    }
    
    func testCreateTemplate_DuplicateName_SetsError() {
        // Given: A view model with an existing template
        let existingTemplate = TestHelpers.createTestWorkoutTemplate(name: "Existing Template")
        persistenceController.create(existingTemplate)
        viewModel.handleIntent(.loadData) // Refresh data
        
        let initialTemplateCount = viewModel.templates.count
        
        // When: Trying to create a template with the same name
        viewModel.handleIntent(.createTemplate(name: "Existing Template", summary: "Different summary"))
        
        // Then: An error should be set and no template should be created
        XCTAssertEqual(viewModel.templates.count, initialTemplateCount, "Template count should not change")
        XCTAssertNotNil(viewModel.error, "An error should be set for duplicate template name")
        
        // Verify the error is a validation error
        if let error = viewModel.error {
            XCTAssertTrue(error is ValidationError, "Error should be a ValidationError")
        }
    }
    
    func testDuplicateTemplate_ValidTemplate_CreatesCopy() {
        // Given: A view model with an existing template
        let originalTemplate = TestHelpers.createTestWorkoutTemplate(name: "Original Template")
        persistenceController.create(originalTemplate)
        viewModel.handleIntent(.loadData) // Refresh data
        
        let initialTemplateCount = viewModel.templates.count
        
        // When: Duplicating the template
        viewModel.handleIntent(.duplicateTemplate(id: originalTemplate.id))
        
        // Then: A copy should be created with a unique name
        XCTAssertEqual(viewModel.templates.count, initialTemplateCount + 1, "Template count should increase by 1")
        XCTAssertTrue(viewModel.templates.contains { $0.name == "Original Template Copy" }, "Duplicate should have 'Copy' suffix")
        XCTAssertNil(viewModel.error, "No error should occur during duplication")
        
        // Verify the duplicate was persisted
        let persistedTemplates = persistenceController.fetch(WorkoutTemplate.self)
        XCTAssertTrue(persistedTemplates.contains { $0.name == "Original Template Copy" }, "Duplicate should be persisted")
    }
    
    func testDuplicateTemplate_InvalidTemplateID_SetsError() {
        // Given: A view model and an invalid template ID
        let invalidID = UUID()
        let initialTemplateCount = viewModel.templates.count
        
        // When: Trying to duplicate a non-existent template
        viewModel.handleIntent(.duplicateTemplate(id: invalidID))
        
        // Then: An error should be set and no template should be created
        XCTAssertEqual(viewModel.templates.count, initialTemplateCount, "Template count should not change")
        XCTAssertNotNil(viewModel.error, "An error should be set for invalid template ID")
        
        if let error = viewModel.error as? LibraryError {
            XCTAssertEqual(error, LibraryError.templateNotFound, "Should be a template not found error")
        }
    }
    
    func testDeleteTemplate_ValidTemplate_RemovesTemplate() {
        // Given: A view model with an existing template (not in use by active plan)
        let testTemplate = TestHelpers.createTestWorkoutTemplate(name: "Template to Delete")
        persistenceController.create(testTemplate)
        viewModel.handleIntent(.loadData) // Refresh data
        
        let initialTemplateCount = viewModel.templates.count
        
        // When: Deleting the template
        viewModel.handleIntent(.deleteTemplate(id: testTemplate.id))
        
        // Then: Template should be removed
        XCTAssertEqual(viewModel.templates.count, initialTemplateCount - 1, "Template count should decrease by 1")
        XCTAssertFalse(viewModel.templates.contains { $0.id == testTemplate.id }, "Template should be removed from collection")
        XCTAssertNil(viewModel.error, "No error should occur during deletion")
        
        // Verify the template was deleted from persistence
        let persistedTemplates = persistenceController.fetch(WorkoutTemplate.self)
        XCTAssertFalse(persistedTemplates.contains { $0.id == testTemplate.id }, "Template should be deleted from persistence")
    }
    
    func testDeleteTemplate_TemplateInUseByActivePlan_SetsError() {
        // Given: A template that's referenced by an active plan
        let testTemplate = TestHelpers.createTestWorkoutTemplate(name: "Active Template")
        let activePlan = TestHelpers.createTestWorkoutPlan(customName: "Active Plan", template: testTemplate)
        activePlan.isActive = true
        
        persistenceController.create(testTemplate)
        persistenceController.create(activePlan)
        viewModel.handleIntent(.loadData) // Refresh data
        
        let initialTemplateCount = viewModel.templates.count
        
        // When: Trying to delete the template that's in use
        viewModel.handleIntent(.deleteTemplate(id: testTemplate.id))
        
        // Then: An error should be set and template should not be deleted
        XCTAssertEqual(viewModel.templates.count, initialTemplateCount, "Template count should not change")
        XCTAssertNotNil(viewModel.error, "An error should be set for template in use")
        
        if let error = viewModel.error as? LibraryError {
            XCTAssertEqual(error, LibraryError.templateInUseByActivePlan, "Should be a template in use error")
        }
        
        // Verify the template was not deleted
        let persistedTemplates = persistenceController.fetch(WorkoutTemplate.self)
        XCTAssertTrue(persistedTemplates.contains { $0.id == testTemplate.id }, "Template should still exist in persistence")
    }
    
    func testDeleteTemplate_InvalidTemplateID_SetsError() {
        // Given: A view model and an invalid template ID
        let invalidID = UUID()
        let initialTemplateCount = viewModel.templates.count
        
        // When: Trying to delete a non-existent template
        viewModel.handleIntent(.deleteTemplate(id: invalidID))
        
        // Then: An error should be set and no changes should occur
        XCTAssertEqual(viewModel.templates.count, initialTemplateCount, "Template count should not change")
        XCTAssertNotNil(viewModel.error, "An error should be set for invalid template ID")
        
        if let error = viewModel.error as? LibraryError {
            XCTAssertEqual(error, LibraryError.templateNotFound, "Should be a template not found error")
        }
    }
    
    func testUpdateTemplate_ValidData_UpdatesTemplate() throws {
        // Given: A view model with an existing template
        let testTemplate = TestHelpers.createTestWorkoutTemplate(name: "Original Name", summary: "Original Summary")
        persistenceController.create(testTemplate)
        viewModel.handleIntent(.loadData) // Refresh data
        
        let newName = "Updated Name"
        let newSummary = "Updated Summary"
        
        // When: Updating the template
        try viewModel.updateTemplate(testTemplate, name: newName, summary: newSummary)
        
        // Then: Template should be updated
        XCTAssertEqual(testTemplate.name, newName, "Template name should be updated")
        XCTAssertEqual(testTemplate.summary, newSummary, "Template summary should be updated")
        
        // Verify the changes were persisted
        let persistedTemplates = persistenceController.fetch(WorkoutTemplate.self)
        let updatedTemplate = persistedTemplates.first { $0.id == testTemplate.id }
        XCTAssertEqual(updatedTemplate?.name, newName, "Updated name should be persisted")
        XCTAssertEqual(updatedTemplate?.summary, newSummary, "Updated summary should be persisted")
    }
    
    func testCreateWorkoutTemplate_ConvenienceMethod_CreatesTemplate() {
        // Given: A view model and template name
        let templateName = "Convenience Template"
        let initialTemplateCount = viewModel.templates.count
        
        // When: Using the convenience method to create a template
        viewModel.createWorkoutTemplate(name: templateName)
        
        // Then: Template should be created
        XCTAssertEqual(viewModel.templates.count, initialTemplateCount + 1, "Template count should increase by 1")
        XCTAssertTrue(viewModel.templates.contains { $0.name == templateName }, "Template should be added to collection")
        XCTAssertTrue(viewModel.showTemplateSheet, "Template sheet should be shown")
    }
    
    func testDeleteTemplate_ConvenienceMethod_DeletesTemplate() {
        // Given: A view model with an existing template
        let testTemplate = TestHelpers.createTestWorkoutTemplate(name: "Template to Delete")
        persistenceController.create(testTemplate)
        viewModel.handleIntent(.loadData) // Refresh data
        
        let initialTemplateCount = viewModel.templates.count
        
        // When: Using the convenience method to delete a template
        viewModel.deleteTemplate(testTemplate)
        
        // Then: Template should be deleted
        XCTAssertEqual(viewModel.templates.count, initialTemplateCount - 1, "Template count should decrease by 1")
        XCTAssertFalse(viewModel.templates.contains { $0.id == testTemplate.id }, "Template should be removed from collection")
    }
    
    // MARK: - Exercise Management Tests
    
    func testCreateExercise_ValidData_CreatesExercise() {
        // Given: A view model and valid exercise data
        let initialExerciseCount = viewModel.exerciseCatalog.count
        let exerciseName = "New Exercise"
        let exerciseCategory = ExerciseCategory.strength
        let exerciseInstructions = "Test instructions"
        
        // When: Creating an exercise with valid data
        viewModel.handleIntent(.createExercise(
            name: exerciseName,
            category: exerciseCategory,
            instructions: exerciseInstructions,
            mediaAssetID: nil
        ))
        
        // Then: Exercise should be created and added to the catalog
        XCTAssertEqual(viewModel.exerciseCatalog.count, initialExerciseCount + 1, "Exercise count should increase by 1")
        XCTAssertTrue(viewModel.exerciseCatalog.contains { $0.name == exerciseName }, "Exercise should be added to catalog")
        XCTAssertNil(viewModel.error, "No error should occur with valid data")
        
        // Verify the exercise was persisted
        let persistedExercises = persistenceController.fetch(Exercise.self)
        XCTAssertTrue(persistedExercises.contains { $0.name == exerciseName }, "Exercise should be persisted")
    }
    
    func testCreateExercise_DuplicateName_SetsError() {
        // Given: A view model with an existing exercise
        let existingExercise = TestHelpers.createTestExercise(name: "Existing Exercise")
        persistenceController.create(existingExercise)
        viewModel.handleIntent(.loadData) // Refresh data
        
        let initialExerciseCount = viewModel.exerciseCatalog.count
        
        // When: Trying to create an exercise with the same name
        viewModel.handleIntent(.createExercise(
            name: "Existing Exercise",
            category: .cardio,
            instructions: "Different instructions",
            mediaAssetID: nil
        ))
        
        // Then: An error should be set and no exercise should be created
        XCTAssertEqual(viewModel.exerciseCatalog.count, initialExerciseCount, "Exercise count should not change")
        XCTAssertNotNil(viewModel.error, "An error should be set for duplicate exercise name")
        
        if let error = viewModel.error as? LibraryError {
            XCTAssertEqual(error, LibraryError.duplicateExerciseName("Existing Exercise"), "Should be a duplicate exercise name error")
        }
    }
    
    func testDeleteExercise_ValidExercise_RemovesExercise() {
        // Given: A view model with an existing exercise (not in use by templates)
        let testExercise = TestHelpers.createTestExercise(name: "Exercise to Delete")
        persistenceController.create(testExercise)
        viewModel.handleIntent(.loadData) // Refresh data
        
        let initialExerciseCount = viewModel.exerciseCatalog.count
        
        // When: Deleting the exercise
        viewModel.handleIntent(.deleteExercise(id: testExercise.id))
        
        // Then: Exercise should be removed
        XCTAssertEqual(viewModel.exerciseCatalog.count, initialExerciseCount - 1, "Exercise count should decrease by 1")
        XCTAssertFalse(viewModel.exerciseCatalog.contains { $0.id == testExercise.id }, "Exercise should be removed from catalog")
        XCTAssertNil(viewModel.error, "No error should occur during deletion")
        
        // Verify the exercise was deleted from persistence
        let persistedExercises = persistenceController.fetch(Exercise.self)
        XCTAssertFalse(persistedExercises.contains { $0.id == testExercise.id }, "Exercise should be deleted from persistence")
    }
    
    func testDeleteExercise_ExerciseInUseByTemplates_SetsError() {
        // Given: An exercise that's referenced by a template
        let testExercise = TestHelpers.createTestExercise(name: "Exercise in Use")
        let testTemplate = TestHelpers.createTestWorkoutTemplate(name: "Template using Exercise")
        let testDayTemplate = TestHelpers.createTestDayTemplate(weekday: .monday, workoutTemplate: testTemplate)
        let testExerciseTemplate = TestHelpers.createTestExerciseTemplate(
            exercise: testExercise,
            dayTemplate: testDayTemplate
        )
        
        persistenceController.create(testExercise)
        persistenceController.create(testTemplate)
        persistenceController.create(testDayTemplate)
        persistenceController.create(testExerciseTemplate)
        viewModel.handleIntent(.loadData) // Refresh data
        
        let initialExerciseCount = viewModel.exerciseCatalog.count
        
        // When: Trying to delete the exercise that's in use
        viewModel.handleIntent(.deleteExercise(id: testExercise.id))
        
        // Then: An error should be set and exercise should not be deleted
        XCTAssertEqual(viewModel.exerciseCatalog.count, initialExerciseCount, "Exercise count should not change")
        XCTAssertNotNil(viewModel.error, "An error should be set for exercise in use")
        
        if let error = viewModel.error as? LibraryError {
            XCTAssertEqual(error, LibraryError.exerciseInUseByTemplates, "Should be an exercise in use error")
        }
        
        // Verify the exercise was not deleted
        let persistedExercises = persistenceController.fetch(Exercise.self)
        XCTAssertTrue(persistedExercises.contains { $0.id == testExercise.id }, "Exercise should still exist in persistence")
    }
    
    func testDeleteExercise_InvalidExerciseID_SetsError() {
        // Given: A view model and an invalid exercise ID
        let invalidID = UUID()
        let initialExerciseCount = viewModel.exerciseCatalog.count
        
        // When: Trying to delete a non-existent exercise
        viewModel.handleIntent(.deleteExercise(id: invalidID))
        
        // Then: An error should be set and no changes should occur
        XCTAssertEqual(viewModel.exerciseCatalog.count, initialExerciseCount, "Exercise count should not change")
        XCTAssertNotNil(viewModel.error, "An error should be set for invalid exercise ID")
        
        if let error = viewModel.error as? LibraryError {
            XCTAssertEqual(error, LibraryError.exerciseNotFound, "Should be an exercise not found error")
        }
    }
    
    func testCreateExercise_ConvenienceMethod_CreatesExercise() throws {
        // Given: A view model and exercise data
        let exerciseName = "Convenience Exercise"
        let exerciseCategory = ExerciseCategory.mobility
        let exerciseInstructions = "Stretch well"
        let initialExerciseCount = viewModel.exerciseCatalog.count
        
        // When: Using the convenience method to create an exercise
        try viewModel.createExercise(
            name: exerciseName,
            category: exerciseCategory,
            instructions: exerciseInstructions
        )
        
        // Then: Exercise should be created
        XCTAssertEqual(viewModel.exerciseCatalog.count, initialExerciseCount + 1, "Exercise count should increase by 1")
        XCTAssertTrue(viewModel.exerciseCatalog.contains { $0.name == exerciseName }, "Exercise should be added to catalog")
        
        // Verify the exercise details
        let createdExercise = viewModel.exerciseCatalog.first { $0.name == exerciseName }
        XCTAssertEqual(createdExercise?.category, exerciseCategory, "Exercise category should match")
        XCTAssertEqual(createdExercise?.instructions, exerciseInstructions, "Exercise instructions should match")
    }
    
    func testUpdateExercise_ValidData_UpdatesExercise() throws {
        // Given: A view model with an existing exercise
        let testExercise = TestHelpers.createTestExercise(
            name: "Original Exercise",
            category: .strength,
            instructions: "Original instructions"
        )
        persistenceController.create(testExercise)
        viewModel.handleIntent(.loadData) // Refresh data
        
        let newName = "Updated Exercise"
        let newCategory = ExerciseCategory.cardio
        let newInstructions = "Updated instructions"
        
        // When: Updating the exercise
        try viewModel.updateExercise(
            testExercise,
            name: newName,
            category: newCategory,
            instructions: newInstructions
        )
        
        // Then: Exercise should be updated
        XCTAssertEqual(testExercise.name, newName, "Exercise name should be updated")
        XCTAssertEqual(testExercise.category, newCategory, "Exercise category should be updated")
        XCTAssertEqual(testExercise.instructions, newInstructions, "Exercise instructions should be updated")
        
        // Verify the changes were persisted
        let persistedExercises = persistenceController.fetch(Exercise.self)
        let updatedExercise = persistedExercises.first { $0.id == testExercise.id }
        XCTAssertEqual(updatedExercise?.name, newName, "Updated name should be persisted")
        XCTAssertEqual(updatedExercise?.category, newCategory, "Updated category should be persisted")
        XCTAssertEqual(updatedExercise?.instructions, newInstructions, "Updated instructions should be persisted")
    }
    
    func testDeleteExercise_ConvenienceMethod_DeletesExercise() {
        // Given: A view model with an existing exercise
        let testExercise = TestHelpers.createTestExercise(name: "Exercise to Delete")
        persistenceController.create(testExercise)
        viewModel.handleIntent(.loadData) // Refresh data
        
        let initialExerciseCount = viewModel.exerciseCatalog.count
        
        // When: Using the convenience method to delete an exercise
        viewModel.deleteExercise(testExercise)
        
        // Then: Exercise should be deleted
        XCTAssertEqual(viewModel.exerciseCatalog.count, initialExerciseCount - 1, "Exercise count should decrease by 1")
        XCTAssertFalse(viewModel.exerciseCatalog.contains { $0.id == testExercise.id }, "Exercise should be removed from catalog")
    }
    
    func testExerciseCatalogSorting_MaintainsAlphabeticalOrder() {
        // Given: Exercises with different names
        let exerciseZ = TestHelpers.createTestExercise(name: "Zebra Exercise")
        let exerciseA = TestHelpers.createTestExercise(name: "Alpha Exercise")
        let exerciseM = TestHelpers.createTestExercise(name: "Middle Exercise")
        
        persistenceController.create(exerciseZ)
        persistenceController.create(exerciseA)
        persistenceController.create(exerciseM)
        
        // Create new view model to load data
        let newViewModel = LibraryViewModel(modelContext: persistenceController.context)
        
        // Then: Exercises should be sorted alphabetically
        let sortedNames = newViewModel.sortedExercises.map { $0.name }
        XCTAssertEqual(sortedNames.first, "Alpha Exercise", "First exercise should be alphabetically first")
        XCTAssertEqual(sortedNames.last, "Zebra Exercise", "Last exercise should be alphabetically last")
        
        // Verify that the convenience property also returns sorted exercises
        let convenienceNames = newViewModel.exercises.map { $0.name }
        XCTAssertEqual(sortedNames, convenienceNames, "Convenience property should return same sorted order")
    }
}