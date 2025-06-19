import Foundation
import SwiftData
import Combine

@MainActor
class LibraryViewModel: ObservableObject {
    // MARK: - Published State
    @Published var templates: [WorkoutTemplate] = []
    @Published var exerciseCatalog: [Exercise] = []
    @Published var activePlanID: UUID?
    @Published var showTemplateSheet: Bool = false
    @Published var showExerciseSheet: Bool = false
    @Published var error: Error?
    @Published var state: LoadingState = .idle
    
    // MARK: - Computed Properties
    var activePlan: WorkoutPlan? {
        guard let activePlanID = activePlanID else { return nil }
        return fetchActivePlan(with: activePlanID)
    }
    
    var canCreateTemplate: Bool {
        return true // Always allow template creation
    }
    
    var sortedTemplates: [WorkoutTemplate] {
        templates.sorted { $0.createdAt > $1.createdAt }
    }
    
    var sortedExercises: [Exercise] {
        exerciseCatalog.sorted { $0.name < $1.name }
    }
    
    // MARK: - Private Properties
    private let modelContext: ModelContext
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        print("🔄 [LibraryViewModel.init] Initialized with ModelContext")
        loadData()
    }
    
    // MARK: - Intent Handling
    func handleIntent(_ intent: LibraryIntent) {
        print("🔄 [LibraryViewModel.handleIntent] Processing intent: \(intent)")
        
        switch intent {
        case .loadData:
            loadData()
            
        case .createTemplate(let name, let summary):
            createTemplate(name: name, summary: summary)
            
        case .duplicateTemplate(let id):
            duplicateTemplate(id: id)
            
        case .deleteTemplate(let id):
            deleteTemplate(id: id)
            
        case .createExercise(let name, let category, let instructions, let mediaAssetID):
            createExercise(name: name, category: category, instructions: instructions, mediaAssetID: mediaAssetID)
            
        case .deleteExercise(let id):
            deleteExercise(id: id)
            
        case .activatePlan(let templateID, let customName, let startDate):
            activatePlan(templateID: templateID, customName: customName, startDate: startDate)
            
        case .deactivatePlan:
            deactivatePlan()
            
        case .showTemplateSheet(let show):
            showTemplateSheet = show
            
        case .showExerciseSheet(let show):
            showExerciseSheet = show
            
        case .clearError:
            error = nil
        }
    }
    
    // MARK: - Data Loading
    private func loadData() {
        print("🔄 [LibraryViewModel.loadData] Starting data load")
        state = .loading
        
        do {
            try loadTemplates()
            try loadExercises()
            try loadActivePlan()
            
            print("✅ [LibraryViewModel.loadData] Successfully loaded all data")
            print("📊 [LibraryViewModel] State changed to: loaded")
            state = .loaded
        } catch {
            print("❌ [LibraryViewModel.loadData] Error: \(error.localizedDescription)")
            print("📊 [LibraryViewModel] State changed to: error")
            self.error = error
            state = .error
        }
    }
    
    private func loadTemplates() throws {
        let descriptor = FetchDescriptor<WorkoutTemplate>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            templates = try modelContext.fetch(descriptor)
            print("📊 [LibraryViewModel.loadTemplates] Loaded \(templates.count) templates")
        } catch {
            print("❌ [LibraryViewModel.loadTemplates] Error: \(error.localizedDescription)")
            templates = []
            throw error
        }
    }
    
    private func loadExercises() throws {
        let descriptor = FetchDescriptor<Exercise>(
            sortBy: [SortDescriptor(\.name)]
        )
        
        do {
            exerciseCatalog = try modelContext.fetch(descriptor)
            print("📊 [LibraryViewModel.loadExercises] Loaded \(exerciseCatalog.count) exercises")
        } catch {
            print("❌ [LibraryViewModel.loadExercises] Error: \(error.localizedDescription)")
            exerciseCatalog = []
            throw error
        }
    }
    
    private func loadActivePlan() throws {
        let descriptor = FetchDescriptor<WorkoutPlan>(
            predicate: #Predicate<WorkoutPlan> { plan in
                plan.isActive == true
            }
        )
        
        do {
            let activePlans = try modelContext.fetch(descriptor)
            activePlanID = activePlans.first?.id
            
            if let activePlanID = activePlanID {
                print("📊 [LibraryViewModel.loadActivePlan] Found active plan: \(activePlanID)")
            } else {
                print("📊 [LibraryViewModel.loadActivePlan] No active plan found")
            }
        } catch {
            print("❌ [LibraryViewModel.loadActivePlan] Error: \(error.localizedDescription)")
            activePlanID = nil
            throw error
        }
    }
    
    // MARK: - Template Operations
    private func createTemplate(name: String, summary: String) {
        print("🔄 [LibraryViewModel.createTemplate] Creating template: \(name)")
        
        do {
            let template = try WorkoutTemplate.createAndSave(
                name: name,
                summary: summary,
                in: modelContext
            )
            
            templates.insert(template, at: 0) // Add to beginning for newest-first display
            print("✅ [LibraryViewModel.createTemplate] Successfully created template: \(name)")
            
            // Auto-show template sheet for editing
            showTemplateSheet = true
            
        } catch {
            print("❌ [LibraryViewModel.createTemplate] Error: \(error.localizedDescription)")
            self.error = error
        }
    }
    
    private func duplicateTemplate(id: UUID) {
        print("🔄 [LibraryViewModel.duplicateTemplate] Duplicating template: \(id)")
        
        guard let originalTemplate = templates.first(where: { $0.id == id }) else {
            print("❌ [LibraryViewModel.duplicateTemplate] Template not found: \(id)")
            error = LibraryError.templateNotFound
            return
        }
        
        do {
            // Generate unique name
            let baseName = originalTemplate.name
            let uniqueName = generateUniqueName(baseName: baseName)
            
            // Create new template
            let duplicatedTemplate = WorkoutTemplate(
                name: uniqueName,
                summary: originalTemplate.summary
            )
            
            modelContext.insert(duplicatedTemplate)
            
            // Duplicate day templates and their exercise templates
            for originalDay in originalTemplate.dayTemplates {
                let duplicatedDay = DayTemplate(
                    weekday: originalDay.weekday,
                    isRest: originalDay.isRest,
                    notes: originalDay.notes,
                    workoutTemplate: duplicatedTemplate
                )
                
                modelContext.insert(duplicatedDay)
                duplicatedTemplate.dayTemplates.append(duplicatedDay)
                
                // Duplicate exercise templates
                for originalExercise in originalDay.exerciseTemplates {
                    let duplicatedExercise = ExerciseTemplate(
                        exercise: originalExercise.exercise,
                        setCount: originalExercise.setCount,
                        reps: originalExercise.reps,
                        weight: originalExercise.weight,
                        position: originalExercise.position,
                        supersetID: originalExercise.supersetID,
                        dayTemplate: duplicatedDay
                    )
                    
                    modelContext.insert(duplicatedExercise)
                    duplicatedDay.exerciseTemplates.append(duplicatedExercise)
                }
            }
            
            try duplicatedTemplate.validateAndSave(in: modelContext)
            templates.insert(duplicatedTemplate, at: 0)
            
            print("✅ [LibraryViewModel.duplicateTemplate] Successfully duplicated template: \(uniqueName)")
            
        } catch {
            print("❌ [LibraryViewModel.duplicateTemplate] Error: \(error.localizedDescription)")
            self.error = error
        }
    }
    
    private func deleteTemplate(id: UUID) {
        print("🔄 [LibraryViewModel.deleteTemplate] Deleting template: \(id)")
        
        guard let template = templates.first(where: { $0.id == id }) else {
            print("❌ [LibraryViewModel.deleteTemplate] Template not found: \(id)")
            error = LibraryError.templateNotFound
            return
        }
        
        // Check if template is referenced by active plan
        if let activePlan = activePlan, activePlan.template?.id == id {
            print("❌ [LibraryViewModel.deleteTemplate] Cannot delete template referenced by active plan")
            error = LibraryError.templateInUseByActivePlan
            return
        }
        
        do {
            // Delete all related data (cascade delete)
            for dayTemplate in template.dayTemplates {
                for exerciseTemplate in dayTemplate.exerciseTemplates {
                    modelContext.delete(exerciseTemplate)
                }
                modelContext.delete(dayTemplate)
            }
            
            modelContext.delete(template)
            try modelContext.save()
            
            // Remove from local array
            templates.removeAll { $0.id == id }
            
            print("✅ [LibraryViewModel.deleteTemplate] Successfully deleted template: \(id)")
            
        } catch {
            print("❌ [LibraryViewModel.deleteTemplate] Error: \(error.localizedDescription)")
            self.error = error
        }
    }
    
    // MARK: - Exercise Operations
    private func createExercise(name: String, category: ExerciseCategory, instructions: String, mediaAssetID: String?) {
        print("🔄 [LibraryViewModel.createExercise] Creating exercise: \(name)")
        
        // Check for duplicate names
        if exerciseCatalog.contains(where: { $0.name.lowercased() == name.lowercased() }) {
            print("❌ [LibraryViewModel.createExercise] Duplicate exercise name: \(name)")
            error = LibraryError.duplicateExerciseName(name)
            return
        }
        
        do {
            let exercise = Exercise(
                name: name,
                category: category,
                instructions: instructions,
                mediaAssetID: mediaAssetID
            )
            
            modelContext.insert(exercise)
            try modelContext.save()
            
            exerciseCatalog.append(exercise)
            exerciseCatalog.sort { $0.name < $1.name }
            
            print("✅ [LibraryViewModel.createExercise] Successfully created exercise: \(name)")
            
        } catch {
            print("❌ [LibraryViewModel.createExercise] Error: \(error.localizedDescription)")
            self.error = error
        }
    }
    
    private func deleteExercise(id: UUID) {
        print("🔄 [LibraryViewModel.deleteExercise] Deleting exercise: \(id)")
        
        guard let exercise = exerciseCatalog.first(where: { $0.id == id }) else {
            print("❌ [LibraryViewModel.deleteExercise] Exercise not found: \(id)")
            error = LibraryError.exerciseNotFound
            return
        }
        
        // Check if exercise is referenced by any exercise templates
        let templateDescriptor = FetchDescriptor<ExerciseTemplate>()
        do {
            let allExerciseTemplates = try modelContext.fetch(templateDescriptor)
            let referencingTemplates = allExerciseTemplates.filter { $0.exercise.id == id }
            
            if !referencingTemplates.isEmpty {
                print("❌ [LibraryViewModel.deleteExercise] Exercise is referenced by \(referencingTemplates.count) templates")
                error = LibraryError.exerciseInUseByTemplates
                return
            }
            
            modelContext.delete(exercise)
            try modelContext.save()
            
            exerciseCatalog.removeAll { $0.id == id }
            
            print("✅ [LibraryViewModel.deleteExercise] Successfully deleted exercise: \(id)")
            
        } catch {
            print("❌ [LibraryViewModel.deleteExercise] Error: \(error.localizedDescription)")
            self.error = error
        }
    }
    
    // MARK: - Plan Operations
    private func activatePlan(templateID: UUID, customName: String, startDate: Date) {
        print("🔄 [LibraryViewModel.activatePlan] Activating plan from template: \(templateID)")
        
        guard let template = templates.first(where: { $0.id == templateID }) else {
            print("❌ [LibraryViewModel.activatePlan] Template not found: \(templateID)")
            error = LibraryError.templateNotFound
            return
        }
        
        do {
            // Deactivate any existing active plans
            let activeDescriptor = FetchDescriptor<WorkoutPlan>(
                predicate: #Predicate<WorkoutPlan> { plan in
                    plan.isActive == true
                }
            )
            
            let activePlans = try modelContext.fetch(activeDescriptor)
            for plan in activePlans {
                plan.isActive = false
                print("📊 [LibraryViewModel.activatePlan] Deactivated existing plan: \(plan.customName)")
            }
            
            // Create new active plan
            let newPlan = WorkoutPlan(
                customName: customName,
                isActive: true,
                startedAt: startDate,
                template: template
            )
            
            modelContext.insert(newPlan)
            try modelContext.save()
            
            activePlanID = newPlan.id
            
            print("✅ [LibraryViewModel.activatePlan] Successfully activated plan: \(customName)")
            
        } catch {
            print("❌ [LibraryViewModel.activatePlan] Error: \(error.localizedDescription)")
            self.error = error
        }
    }
    
    private func deactivatePlan() {
        print("🔄 [LibraryViewModel.deactivatePlan] Deactivating current plan")
        
        guard let currentActivePlanID = activePlanID,
              let currentPlan = fetchActivePlan(with: currentActivePlanID) else {
            print("❌ [LibraryViewModel.deactivatePlan] No active plan to deactivate")
            error = LibraryError.noActivePlan
            return
        }
        
        do {
            currentPlan.isActive = false
            try modelContext.save()
            
            activePlanID = nil
            
            print("✅ [LibraryViewModel.deactivatePlan] Successfully deactivated plan: \(currentPlan.customName)")
            
        } catch {
            print("❌ [LibraryViewModel.deactivatePlan] Error: \(error.localizedDescription)")
            self.error = error
        }
    }
    
    // MARK: - Helper Methods
    private func fetchActivePlan(with id: UUID) -> WorkoutPlan? {
        let descriptor = FetchDescriptor<WorkoutPlan>(
            predicate: #Predicate<WorkoutPlan> { plan in
                plan.id == id && plan.isActive == true
            }
        )
        
        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            print("❌ [LibraryViewModel.fetchActivePlan] Error: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func generateUniqueName(baseName: String) -> String {
        var counter = 1
        var candidateName = "\(baseName) Copy"
        
        while templates.contains(where: { $0.name.lowercased() == candidateName.lowercased() }) {
            counter += 1
            candidateName = "\(baseName) Copy \(counter)"
        }
        
        return candidateName
    }
}

// MARK: - Supporting Types

enum LoadingState {
    case idle
    case loading
    case loaded
    case error
}

enum LibraryIntent {
    case loadData
    case createTemplate(name: String, summary: String)
    case duplicateTemplate(id: UUID)
    case deleteTemplate(id: UUID)
    case createExercise(name: String, category: ExerciseCategory, instructions: String, mediaAssetID: String?)
    case deleteExercise(id: UUID)
    case activatePlan(templateID: UUID, customName: String, startDate: Date)
    case deactivatePlan
    case showTemplateSheet(Bool)
    case showExerciseSheet(Bool)
    case clearError
}

enum LibraryError: Error, LocalizedError, Equatable {
    case templateNotFound
    case exerciseNotFound
    case templateInUseByActivePlan
    case exerciseInUseByTemplates
    case duplicateExerciseName(String)
    case noActivePlan
    case invalidTemplateData
    case invalidExerciseData
    
    var errorDescription: String? {
        switch self {
        case .templateNotFound:
            return "The requested workout template could not be found."
        case .exerciseNotFound:
            return "The requested exercise could not be found."
        case .templateInUseByActivePlan:
            return "Cannot delete template because it's currently being used by an active workout plan."
        case .exerciseInUseByTemplates:
            return "Cannot delete exercise because it's being used by one or more workout templates."
        case .duplicateExerciseName(let name):
            return "An exercise with the name '\(name)' already exists."
        case .noActivePlan:
            return "No active workout plan found."
        case .invalidTemplateData:
            return "The template data is invalid or corrupted."
        case .invalidExerciseData:
            return "The exercise data is invalid or corrupted."
        }
    }
}

 