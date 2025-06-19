import XCTest
import SwiftData
@testable import UzoFitness

@MainActor
final class LibraryViewModelTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var viewModel: LibraryViewModel!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory model container for testing
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: 
            WorkoutTemplate.self,
            DayTemplate.self,
            ExerciseTemplate.self,
            Exercise.self,
            WorkoutPlan.self,
            WorkoutSession.self,
            SessionExercise.self,
            CompletedSet.self,
            PerformedExercise.self,
            ProgressPhoto.self,
            configurations: config
        )
        
        modelContext = modelContainer.mainContext
        viewModel = LibraryViewModel(modelContext: modelContext)
        
        print("✅ [LibraryViewModelTests.setUp] Test environment initialized")
    }
    
    override func tearDown() async throws {
        viewModel = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
        
        print("✅ [LibraryViewModelTests.tearDown] Test environment cleaned up")
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization_SetsDefaultState() async throws {
        // Then
        XCTAssertEqual(viewModel.templates.count, 0)
        XCTAssertEqual(viewModel.exerciseCatalog.count, 0)
        XCTAssertNil(viewModel.activePlanID)
        XCTAssertFalse(viewModel.showTemplateSheet)
        XCTAssertFalse(viewModel.showExerciseSheet)
        XCTAssertNil(viewModel.error)
        
        print("✅ [LibraryViewModelTests.testInitialization_SetsDefaultState] Passed")
    }
    
    // MARK: - Template Management Tests
    
    func testCreateTemplate_ValidData_CreatesTemplate() async throws {
        // Given
        let templateName = "Push Pull Legs"
        let templateSummary = "Classic 3-day split"
        
        // When
        viewModel.handleIntent(.createTemplate(name: templateName, summary: templateSummary))
        
        // Then
        XCTAssertEqual(viewModel.templates.count, 1)
        XCTAssertEqual(viewModel.templates.first?.name, templateName)
        XCTAssertEqual(viewModel.templates.first?.summary, templateSummary)
        XCTAssertTrue(viewModel.showTemplateSheet)
        XCTAssertNil(viewModel.error)
        
        print("✅ [LibraryViewModelTests.testCreateTemplate_ValidData_CreatesTemplate] Passed")
    }
    
    func testCreateTemplate_DuplicateName_SetsError() async throws {
        // Given
        let templateName = "Upper Lower"
        let template = WorkoutTemplate(name: templateName, summary: "Test template")
        modelContext.insert(template)
        try modelContext.save()
        
        viewModel.handleIntent(.loadData) // Refresh data
        
        // When
        viewModel.handleIntent(.createTemplate(name: templateName, summary: "Duplicate"))
        
        // Then
        XCTAssertNotNil(viewModel.error)
        XCTAssertEqual(viewModel.templates.count, 1) // Should still be just the original
        
        print("✅ [LibraryViewModelTests.testCreateTemplate_DuplicateName_SetsError] Passed")
    }
    
    func testDuplicateTemplate_ValidTemplate_CreatesCopy() async throws {
        // Given
        let exercise = Exercise(name: "Bench Press", category: .strength)
        let originalTemplate = WorkoutTemplate(name: "Original Template", summary: "Test")
        let dayTemplate = DayTemplate(weekday: .monday, workoutTemplate: originalTemplate)
        let exerciseTemplate = ExerciseTemplate(
            exercise: exercise,
            setCount: 3,
            reps: 10,
            weight: 135.0,
            position: 1.0,
            dayTemplate: dayTemplate
        )
        
        modelContext.insert(exercise)
        modelContext.insert(originalTemplate)
        modelContext.insert(dayTemplate)
        modelContext.insert(exerciseTemplate)
        
        originalTemplate.dayTemplates.append(dayTemplate)
        dayTemplate.exerciseTemplates.append(exerciseTemplate)
        
        try modelContext.save()
        
        viewModel.handleIntent(.loadData)
        
        // When
        viewModel.handleIntent(.duplicateTemplate(id: originalTemplate.id))
        
        // Then
        XCTAssertEqual(viewModel.templates.count, 2)
        
        let duplicatedTemplate = viewModel.templates.first { $0.name.contains("Copy") }
        XCTAssertNotNil(duplicatedTemplate)
        XCTAssertEqual(duplicatedTemplate?.name, "Original Template Copy")
        XCTAssertEqual(duplicatedTemplate?.summary, "Test")
        XCTAssertEqual(duplicatedTemplate?.dayTemplates.count, 1)
        XCTAssertEqual(duplicatedTemplate?.dayTemplates.first?.exerciseTemplates.count, 1)
        
        print("✅ [LibraryViewModelTests.testDuplicateTemplate_ValidTemplate_CreatesCopy] Passed")
    }
    
    func testDeleteTemplate_ValidTemplate_RemovesTemplate() async throws {
        // Given
        let template = WorkoutTemplate(name: "Test Template", summary: "To be deleted")
        modelContext.insert(template)
        try modelContext.save()
        
        viewModel.handleIntent(.loadData)
        
        // When
        viewModel.handleIntent(.deleteTemplate(id: template.id))
        
        // Then
        XCTAssertEqual(viewModel.templates.count, 0)
        XCTAssertNil(viewModel.error)
        
        print("✅ [LibraryViewModelTests.testDeleteTemplate_ValidTemplate_RemovesTemplate] Passed")
    }
    
    func testDeleteTemplate_TemplateInUseByActivePlan_SetsError() async throws {
        // Given
        let template = WorkoutTemplate(name: "Active Template", summary: "In use")
        let activePlan = WorkoutPlan(customName: "Active Plan", isActive: true, template: template)
        
        modelContext.insert(template)
        modelContext.insert(activePlan)
        try modelContext.save()
        
        viewModel.handleIntent(.loadData)
        
        // When
        viewModel.handleIntent(.deleteTemplate(id: template.id))
        
        // Then
        XCTAssertEqual(viewModel.templates.count, 1) // Should still exist
        XCTAssertNotNil(viewModel.error)
        
        if let error = viewModel.error as? LibraryError {
            XCTAssertEqual(error, LibraryError.templateInUseByActivePlan)
        }
        
        print("✅ [LibraryViewModelTests.testDeleteTemplate_TemplateInUseByActivePlan_SetsError] Passed")
    }
    
    // MARK: - Exercise Management Tests
    
    func testCreateExercise_ValidData_CreatesExercise() async throws {
        // Given
        let exerciseName = "Deadlift"
        let category = ExerciseCategory.strength
        let instructions = "Hip hinge movement"
        
        // When
        viewModel.handleIntent(.createExercise(name: exerciseName, category: category, instructions: instructions, mediaAssetID: nil))
        
        // Then
        XCTAssertEqual(viewModel.exerciseCatalog.count, 1)
        XCTAssertEqual(viewModel.exerciseCatalog.first?.name, exerciseName)
        XCTAssertEqual(viewModel.exerciseCatalog.first?.category, category)
        XCTAssertEqual(viewModel.exerciseCatalog.first?.instructions, instructions)
        XCTAssertNil(viewModel.error)
        
        print("✅ [LibraryViewModelTests.testCreateExercise_ValidData_CreatesExercise] Passed")
    }
    
    func testCreateExercise_DuplicateName_SetsError() async throws {
        // Given
        let exerciseName = "Squat"
        let exercise = Exercise(name: exerciseName, category: .strength)
        modelContext.insert(exercise)
        try modelContext.save()
        
        viewModel.handleIntent(.loadData)
        
        // When
        viewModel.handleIntent(.createExercise(name: exerciseName, category: .strength, instructions: "Duplicate", mediaAssetID: nil))
        
        // Then
        XCTAssertEqual(viewModel.exerciseCatalog.count, 1) // Should still be just the original
        XCTAssertNotNil(viewModel.error)
        
        if let error = viewModel.error as? LibraryError {
            XCTAssertEqual(error, LibraryError.duplicateExerciseName(exerciseName))
        }
        
        print("✅ [LibraryViewModelTests.testCreateExercise_DuplicateName_SetsError] Passed")
    }
    
    func testDeleteExercise_ValidExercise_RemovesExercise() async throws {
        // Given
        let exercise = Exercise(name: "Pull-up", category: .strength)
        modelContext.insert(exercise)
        try modelContext.save()
        
        viewModel.handleIntent(.loadData)
        
        // When
        viewModel.handleIntent(.deleteExercise(id: exercise.id))
        
        // Then
        XCTAssertEqual(viewModel.exerciseCatalog.count, 0)
        XCTAssertNil(viewModel.error)
        
        print("✅ [LibraryViewModelTests.testDeleteExercise_ValidExercise_RemovesExercise] Passed")
    }
    
    func testDeleteExercise_ExerciseInUseByTemplate_SetsError() async throws {
        // Given
        let exercise = Exercise(name: "Bench Press", category: .strength)
        let workoutTemplate = WorkoutTemplate(name: "Test Template")
        let dayTemplate = DayTemplate(weekday: .monday, workoutTemplate: workoutTemplate)
        let exerciseTemplate = ExerciseTemplate(
            exercise: exercise,
            setCount: 3,
            reps: 10,
            weight: 135.0,
            position: 1.0,
            dayTemplate: dayTemplate
        )
        
        modelContext.insert(exercise)
        modelContext.insert(workoutTemplate)
        modelContext.insert(dayTemplate)
        modelContext.insert(exerciseTemplate)
        try modelContext.save()
        
        viewModel.handleIntent(.loadData)
        
        // When
        viewModel.handleIntent(.deleteExercise(id: exercise.id))
        
        // Then
        XCTAssertEqual(viewModel.exerciseCatalog.count, 1) // Should still exist
        XCTAssertNotNil(viewModel.error)
        
        if let error = viewModel.error as? LibraryError {
            XCTAssertEqual(error, LibraryError.exerciseInUseByTemplates)
        }
        
        print("✅ [LibraryViewModelTests.testDeleteExercise_ExerciseInUseByTemplate_SetsError] Passed")
    }
    
    // MARK: - Plan Management Tests
    
    func testActivatePlan_ValidTemplate_CreatesActivePlan() async throws {
        // Given
        let template = WorkoutTemplate(name: "Test Template", summary: "Test")
        modelContext.insert(template)
        try modelContext.save()
        
        viewModel.handleIntent(.loadData)
        
        let customName = "My Workout Plan"
        let startDate = Date()
        
        // When
        viewModel.handleIntent(.activatePlan(templateID: template.id, customName: customName, startDate: startDate))
        
        // Then
        XCTAssertNotNil(viewModel.activePlanID)
        XCTAssertNotNil(viewModel.activePlan)
        XCTAssertEqual(viewModel.activePlan?.customName, customName)
        XCTAssertTrue(viewModel.activePlan?.isActive == true)
        XCTAssertEqual(viewModel.activePlan?.template?.id, template.id)
        XCTAssertNil(viewModel.error)
        
        print("✅ [LibraryViewModelTests.testActivatePlan_ValidTemplate_CreatesActivePlan] Passed")
    }
    
    func testActivatePlan_ExistingActivePlan_DeactivatesOldPlan() async throws {
        // Given
        let template1 = WorkoutTemplate(name: "Template 1", summary: "First")
        let template2 = WorkoutTemplate(name: "Template 2", summary: "Second")
        let oldPlan = WorkoutPlan(customName: "Old Plan", isActive: true, template: template1)
        
        modelContext.insert(template1)
        modelContext.insert(template2)
        modelContext.insert(oldPlan)
        try modelContext.save()
        
        viewModel.handleIntent(.loadData)
        
        // When
        viewModel.handleIntent(.activatePlan(templateID: template2.id, customName: "New Plan", startDate: Date()))
        
        // Then
        XCTAssertNotNil(viewModel.activePlanID)
        XCTAssertEqual(viewModel.activePlan?.customName, "New Plan")
        XCTAssertEqual(viewModel.activePlan?.template?.id, template2.id)
        
        // Check that old plan is deactivated
        let descriptor = FetchDescriptor<WorkoutPlan>()
        let allPlans = try modelContext.fetch(descriptor)
        let oldPlanUpdated = allPlans.first { $0.id == oldPlan.id }
        XCTAssertFalse(oldPlanUpdated?.isActive == true)
        
        print("✅ [LibraryViewModelTests.testActivatePlan_ExistingActivePlan_DeactivatesOldPlan] Passed")
    }
    
    func testDeactivatePlan_WithActivePlan_DeactivatesPlan() async throws {
        // Given
        let template = WorkoutTemplate(name: "Test Template", summary: "Test")
        let activePlan = WorkoutPlan(customName: "Active Plan", isActive: true, template: template)
        
        modelContext.insert(template)
        modelContext.insert(activePlan)
        try modelContext.save()
        
        viewModel.handleIntent(.loadData)
        
        // When
        viewModel.handleIntent(.deactivatePlan)
        
        // Then
        XCTAssertNil(viewModel.activePlanID)
        XCTAssertNil(viewModel.activePlan)
        XCTAssertNil(viewModel.error)
        
        // Check that plan is deactivated in the database
        let descriptor = FetchDescriptor<WorkoutPlan>()
        let allPlans = try modelContext.fetch(descriptor)
        let planUpdated = allPlans.first { $0.id == activePlan.id }
        XCTAssertFalse(planUpdated?.isActive == true)
        
        print("✅ [LibraryViewModelTests.testDeactivatePlan_WithActivePlan_DeactivatesPlan] Passed")
    }
    
    func testDeactivatePlan_NoActivePlan_SetsError() async throws {
        // Given - no active plan
        
        // When
        viewModel.handleIntent(.deactivatePlan)
        
        // Then
        XCTAssertNotNil(viewModel.error)
        
        if let error = viewModel.error as? LibraryError {
            XCTAssertEqual(error, LibraryError.noActivePlan)
        }
        
        print("✅ [LibraryViewModelTests.testDeactivatePlan_NoActivePlan_SetsError] Passed")
    }
    
    // MARK: - Computed Properties Tests
    
    func testSortedTemplates_MultipleTemplates_SortsCorrectly() async throws {
        // Given
        let template1 = WorkoutTemplate(name: "Template A", summary: "First", createdAt: Date().addingTimeInterval(-3600))
        let template2 = WorkoutTemplate(name: "Template B", summary: "Second", createdAt: Date())
        
        modelContext.insert(template1)
        modelContext.insert(template2)
        try modelContext.save()
        
        viewModel.handleIntent(.loadData)
        
        // When
        let sortedTemplates = viewModel.sortedTemplates
        
        // Then
        XCTAssertEqual(sortedTemplates.count, 2)
        XCTAssertEqual(sortedTemplates.first?.name, "Template B") // Newer first
        XCTAssertEqual(sortedTemplates.last?.name, "Template A")
        
        print("✅ [LibraryViewModelTests.testSortedTemplates_MultipleTemplates_SortsCorrectly] Passed")
    }
    
    func testSortedExercises_MultipleExercises_SortsAlphabetically() async throws {
        // Given
        let exercise1 = Exercise(name: "Squat", category: .strength)
        let exercise2 = Exercise(name: "Bench Press", category: .strength)
        let exercise3 = Exercise(name: "Deadlift", category: .strength)
        
        modelContext.insert(exercise1)
        modelContext.insert(exercise2)
        modelContext.insert(exercise3)
        try modelContext.save()
        
        viewModel.handleIntent(.loadData)
        
        // When
        let sortedExercises = viewModel.sortedExercises
        
        // Then
        XCTAssertEqual(sortedExercises.count, 3)
        XCTAssertEqual(sortedExercises[0].name, "Bench Press")
        XCTAssertEqual(sortedExercises[1].name, "Deadlift")
        XCTAssertEqual(sortedExercises[2].name, "Squat")
        
        print("✅ [LibraryViewModelTests.testSortedExercises_MultipleExercises_SortsAlphabetically] Passed")
    }
    
    // MARK: - UI State Tests
    
    func testShowTemplateSheet_Toggle_UpdatesState() async throws {
        // When
        viewModel.handleIntent(.showTemplateSheet(true))
        
        // Then
        XCTAssertTrue(viewModel.showTemplateSheet)
        
        // When
        viewModel.handleIntent(.showTemplateSheet(false))
        
        // Then
        XCTAssertFalse(viewModel.showTemplateSheet)
        
        print("✅ [LibraryViewModelTests.testShowTemplateSheet_Toggle_UpdatesState] Passed")
    }
    
    func testShowExerciseSheet_Toggle_UpdatesState() async throws {
        // When
        viewModel.handleIntent(.showExerciseSheet(true))
        
        // Then
        XCTAssertTrue(viewModel.showExerciseSheet)
        
        // When
        viewModel.handleIntent(.showExerciseSheet(false))
        
        // Then
        XCTAssertFalse(viewModel.showExerciseSheet)
        
        print("✅ [LibraryViewModelTests.testShowExerciseSheet_Toggle_UpdatesState] Passed")
    }
    
    func testClearError_WithError_ClearsError() async throws {
        // Given
        viewModel.error = LibraryError.templateNotFound
        
        // When
        viewModel.handleIntent(.clearError)
        
        // Then
        XCTAssertNil(viewModel.error)
        
        print("✅ [LibraryViewModelTests.testClearError_WithError_ClearsError] Passed")
    }
    
    // MARK: - Edge Cases Tests
    
    func testGenerateUniqueName_MultipleConflicts_GeneratesCorrectName() async throws {
        // Given
        let template1 = WorkoutTemplate(name: "Test Template", summary: "Original")
        let template2 = WorkoutTemplate(name: "Test Template Copy", summary: "First Copy")
        let template3 = WorkoutTemplate(name: "Test Template Copy 2", summary: "Second Copy")
        
        modelContext.insert(template1)
        modelContext.insert(template2)
        modelContext.insert(template3)
        try modelContext.save()
        
        viewModel.handleIntent(.loadData)
        
        // When
        viewModel.handleIntent(.duplicateTemplate(id: template1.id))
        
        // Then
        let newTemplate = viewModel.templates.first { $0.name == "Test Template Copy 3" }
        XCTAssertNotNil(newTemplate)
        
        print("✅ [LibraryViewModelTests.testGenerateUniqueName_MultipleConflicts_GeneratesCorrectName] Passed")
    }
} 