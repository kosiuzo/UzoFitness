import Foundation
import OSLog
import SwiftData
import Combine
import OSLog

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
    @Published var selectedSegment: LibrarySegment = .workouts
    @Published var importErrorMessage: String?
    @Published var workoutPlans: [WorkoutPlan] = []
    
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
        // Use cached exercises if available, fallback to exerciseCatalog
        if _isExercisesLoaded {
            return _cachedExercises // Already sorted from database query
        } else {
            return exerciseCatalog.sorted { $0.name < $1.name }
        }
    }
    
    // Convenience properties for the UI
    var exercises: [Exercise] {
        sortedExercises
    }
    
    var workoutTemplates: [WorkoutTemplate] {
        sortedTemplates
    }
    
    // MARK: - Private Properties
    private let modelContext: ModelContext
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Exercise Caching
    private var _cachedExercises: [Exercise] = []
    private var _isExercisesLoaded = false
    
    // MARK: - Public Methods for View Access
    func deleteExerciseTemplate(_ exerciseTemplate: ExerciseTemplate) {
        AppLogger.debug("[LibraryViewModel.deleteExerciseTemplate] Deleting exercise template for \(exerciseTemplate.exercise.name)", category: "LibraryViewModel")
        
        // Remove from day template
        exerciseTemplate.dayTemplate?.exerciseTemplates.removeAll { $0.id == exerciseTemplate.id }
        
        // Delete from context
        modelContext.delete(exerciseTemplate)
        
        do {
            try modelContext.save()
            AppLogger.info("[LibraryViewModel.deleteExerciseTemplate] Successfully deleted exercise template", category: "LibraryViewModel")
        } catch {
            AppLogger.error("[LibraryViewModel.deleteExerciseTemplate] Error: \(error.localizedDescription)", category: "LibraryViewModel", error: error)
            self.error = error
        }
    }
    
    func reorderExerciseTemplates(in dayTemplate: DayTemplate, from source: IndexSet, to destination: Int) {
        AppLogger.debug("[LibraryViewModel.reorderExerciseTemplates] Reordering exercises in \(dayTemplate.weekday)", category: "LibraryViewModel")
        
        let sortedExercises = dayTemplate.exerciseTemplates.sorted(by: { $0.position < $1.position })
        var reorderedExercises = sortedExercises
        reorderedExercises.move(fromOffsets: source, toOffset: destination)
        
        // Update positions
        for (index, exerciseTemplate) in reorderedExercises.enumerated() {
            exerciseTemplate.position = Double(index + 1)
        }
        
        do {
            try modelContext.save()
            AppLogger.info("[LibraryViewModel.reorderExerciseTemplates] Successfully reordered exercises", category: "LibraryViewModel")
        } catch {
            AppLogger.error("[LibraryViewModel.reorderExerciseTemplates] Error: \(error.localizedDescription)", category: "LibraryViewModel", error: error)
            self.error = error
        }
    }
    
    // MARK: - Initialization
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        AppLogger.debug("[LibraryViewModel.init] Initialized with ModelContext", category: "LibraryViewModel")
        
        // Load exercise cache immediately for instant access
        loadExerciseCache()
        
        // Load other data
        loadData()
    }
    
    // MARK: - Intent Handling
    func handleIntent(_ intent: LibraryIntent) {
        AppLogger.debug("[LibraryViewModel.handleIntent] Processing intent: \(intent)", category: "LibraryViewModel")
        
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
        AppLogger.debug("[LibraryViewModel.loadData] Starting data load", category: "LibraryViewModel")
        state = .loading
        
        do {
            try loadTemplates()
            try loadExercises()
            try loadActivePlan()
            loadWorkoutPlans()
            
            AppLogger.info("[LibraryViewModel.loadData] Successfully loaded all data", category: "LibraryViewModel")
            AppLogger.debug("[LibraryViewModel] State changed to: loaded", category: "LibraryViewModel")
            state = .loaded
        } catch {
            AppLogger.error("[LibraryViewModel.loadData] Error: \(error.localizedDescription)", category: "LibraryViewModel", error: error)
            AppLogger.debug("[LibraryViewModel] State changed to: error", category: "LibraryViewModel")
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
            AppLogger.debug("[LibraryViewModel.loadTemplates] Loaded \(templates.count) templates", category: "LibraryViewModel")
        } catch {
            AppLogger.error("[LibraryViewModel.loadTemplates] Error: \(error.localizedDescription)", category: "LibraryViewModel", error: error)
            templates = []
            throw error
        }
    }
    
    private func loadExercises() throws {
        // Only load if not already cached
        if _isExercisesLoaded {
            AppLogger.debug("[LibraryViewModel.loadExercises] Exercises already cached, skipping load", category: "LibraryViewModel")
            return
        }
        
        // Use the dedicated cache loading method
        loadExerciseCache()
    }
    
    // MARK: - Exercise Cache Management
    private func ensureExercisesLoaded() {
        if !_isExercisesLoaded {
            AppLogger.debug("[LibraryViewModel.ensureExercisesLoaded] Loading exercises into cache", category: "LibraryViewModel")
            do {
                try loadExercises()
            } catch {
                AppLogger.error("[LibraryViewModel.ensureExercisesLoaded] Error loading exercises: \(error.localizedDescription)", category: "LibraryViewModel", error: error)
            }
        }
    }
    
    func getExercises() -> [Exercise] {
        ensureExercisesLoaded()
        return exercises // Use the computed property for consistency
    }
    
    // Force refresh exercises for immediate availability (e.g., when sheet is presented)
    func refreshExercisesForUI() {
        AppLogger.debug("[LibraryViewModel.refreshExercisesForUI] Forcing exercise refresh for UI", category: "LibraryViewModel")
        ensureExercisesLoaded()
        
        // If exercises are cached but exerciseCatalog is empty, sync them
        if _isExercisesLoaded && !_cachedExercises.isEmpty && exerciseCatalog.isEmpty {
            AppLogger.debug("[LibraryViewModel.refreshExercisesForUI] Syncing cached exercises to published property", category: "LibraryViewModel")
            exerciseCatalog = _cachedExercises
        }
    }
    
    // MARK: - Exercise Cache Loading
    private func loadExerciseCache() {
        AppLogger.debug("[LibraryViewModel.loadExerciseCache] Loading exercise cache", category: "LibraryViewModel")
        
        do {
            let descriptor = FetchDescriptor<Exercise>(
                sortBy: [SortDescriptor(\.name)]
            )
            
            _cachedExercises = try modelContext.fetch(descriptor)
            exerciseCatalog = _cachedExercises // Update published property
            _isExercisesLoaded = true
            
            AppLogger.info("[LibraryViewModel.loadExerciseCache] Successfully loaded \(_cachedExercises.count) exercises into cache", category: "LibraryViewModel")
        } catch {
            AppLogger.error("[LibraryViewModel.loadExerciseCache] Error loading exercise cache: \(error.localizedDescription)", category: "LibraryViewModel", error: error)
            _cachedExercises = []
            exerciseCatalog = []
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
                AppLogger.debug("[LibraryViewModel.loadActivePlan] Found active plan: \(activePlanID)", category: "LibraryViewModel")
            } else {
                AppLogger.debug("[LibraryViewModel.loadActivePlan] No active plan found", category: "LibraryViewModel")
            }
        } catch {
            AppLogger.error("[LibraryViewModel.loadActivePlan] Error: \(error.localizedDescription)", category: "LibraryViewModel", error: error)
            activePlanID = nil
            throw error
        }
    }
    
    private func loadWorkoutPlans() {
        do {
            let descriptor = FetchDescriptor<WorkoutPlan>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            workoutPlans = try modelContext.fetch(descriptor)
            AppLogger.debug("[LibraryViewModel.loadWorkoutPlans] Loaded \(workoutPlans.count) workout plans", category: "LibraryViewModel")
        } catch {
            AppLogger.error("[LibraryViewModel.loadWorkoutPlans] Error: \(error.localizedDescription)", category: "LibraryViewModel", error: error)
            workoutPlans = []
        }
    }
    
    // MARK: - Template Operations
    private func createTemplate(name: String, summary: String) {
        AppLogger.debug("[LibraryViewModel.createTemplate] Creating template: \(name)", category: "LibraryViewModel")
        
        do {
            let template = try WorkoutTemplate.createAndSave(
                name: name,
                summary: summary,
                in: modelContext
            )
            
            templates.insert(template, at: 0) // Add to beginning for newest-first display
            AppLogger.info("[LibraryViewModel.createTemplate] Successfully created template: \(name)", category: "LibraryViewModel")
            
            // Auto-show template sheet for editing
            showTemplateSheet = true
            
        } catch {
            AppLogger.error("[LibraryViewModel.createTemplate] Error: \(error.localizedDescription)", category: "LibraryViewModel", error: error)
            self.error = error
        }
    }
    
    private func duplicateTemplate(id: UUID) {
        AppLogger.debug("[LibraryViewModel.duplicateTemplate] Duplicating template: \(id)", category: "LibraryViewModel")
        
        guard let originalTemplate = templates.first(where: { $0.id == id }) else {
            AppLogger.error("[LibraryViewModel.duplicateTemplate] Template not found: \(id)", category: "LibraryViewModel")
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
            
            AppLogger.info("[LibraryViewModel.duplicateTemplate] Successfully duplicated template: \(uniqueName)", category: "LibraryViewModel")
            
        } catch {
            AppLogger.error("[LibraryViewModel.duplicateTemplate] Error: \(error.localizedDescription)", category: "LibraryViewModel", error: error)
            self.error = error
        }
    }
    
    private func deleteTemplate(id: UUID) {
        AppLogger.debug("[LibraryViewModel.deleteTemplate] Deleting template: \(id)", category: "LibraryViewModel")
        
        guard let template = templates.first(where: { $0.id == id }) else {
            AppLogger.error("[LibraryViewModel.deleteTemplate] Template not found: \(id)", category: "LibraryViewModel")
            error = LibraryError.templateNotFound
            return
        }
        
        // Check if template is referenced by active plan
        if let activePlan = activePlan, activePlan.template?.id == id {
            AppLogger.error("[LibraryViewModel.deleteTemplate] Cannot delete template referenced by active plan", category: "LibraryViewModel")
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
            
            AppLogger.info("[LibraryViewModel.deleteTemplate] Successfully deleted template: \(id)", category: "LibraryViewModel")
            
        } catch {
            AppLogger.error("[LibraryViewModel.deleteTemplate] Error: \(error.localizedDescription)", category: "LibraryViewModel", error: error)
            self.error = error
        }
    }
    
    // MARK: - Exercise Operations
    private func createExercise(name: String, category: ExerciseCategory, instructions: String, mediaAssetID: String?) {
        AppLogger.debug("[LibraryViewModel.createExercise] Creating exercise: \(name)", category: "LibraryViewModel")
        
        // Check for duplicate names
        if exerciseCatalog.contains(where: { $0.name.lowercased() == name.lowercased() }) {
            AppLogger.error("[LibraryViewModel.createExercise] Duplicate exercise name: \(name)", category: "LibraryViewModel")
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
            
            // Update cache with new exercise
            _cachedExercises.append(exercise)
            _cachedExercises.sort { $0.name < $1.name }
            exerciseCatalog = _cachedExercises // Update published property to trigger UI updates
            
            AppLogger.info("[LibraryViewModel.createExercise] Successfully created exercise: \(name) and updated cache", category: "LibraryViewModel")
            
        } catch {
            AppLogger.error("[LibraryViewModel.createExercise] Error: \(error.localizedDescription)", category: "LibraryViewModel", error: error)
            self.error = error
        }
    }
    
    private func deleteExercise(id: UUID) {
        AppLogger.debug("[LibraryViewModel.deleteExercise] Deleting exercise: \(id)", category: "LibraryViewModel")
        
        guard let exercise = exerciseCatalog.first(where: { $0.id == id }) else {
            AppLogger.error("[LibraryViewModel.deleteExercise] Exercise not found: \(id)", category: "LibraryViewModel")
            error = LibraryError.exerciseNotFound
            return
        }
        
        // Check if exercise is referenced by any exercise templates
        let templateDescriptor = FetchDescriptor<ExerciseTemplate>()
        do {
            let allExerciseTemplates = try modelContext.fetch(templateDescriptor)
            let referencingTemplates = allExerciseTemplates.filter { $0.exercise.id == id }
            
            if !referencingTemplates.isEmpty {
                AppLogger.error("[LibraryViewModel.deleteExercise] Exercise is referenced by \(referencingTemplates.count) templates", category: "LibraryViewModel")
                error = LibraryError.exerciseInUseByTemplates
                return
            }
            
            modelContext.delete(exercise)
            try modelContext.save()
            
            // Update cache by removing the exercise
            _cachedExercises.removeAll { $0.id == id }
            exerciseCatalog = _cachedExercises // Update published property to trigger UI updates
            
            AppLogger.info("[LibraryViewModel.deleteExercise] Successfully deleted exercise: \(id) and updated cache", category: "LibraryViewModel")
            
        } catch {
            AppLogger.error("[LibraryViewModel.deleteExercise] Error: \(error.localizedDescription)", category: "LibraryViewModel", error: error)
            self.error = error
        }
    }
    
    // MARK: - Plan Operations
    private func activatePlan(templateID: UUID, customName: String, startDate: Date) {
        AppLogger.debug("[LibraryViewModel.activatePlan] Activating plan from template: \(templateID)", category: "LibraryViewModel")
        
        guard let template = templates.first(where: { $0.id == templateID }) else {
            AppLogger.error("[LibraryViewModel.activatePlan] Template not found: \(templateID)", category: "LibraryViewModel")
            error = LibraryError.templateNotFound
            return
        }
        
        do {
            // Deactivate any existing active plans first
            let activeDescriptor = FetchDescriptor<WorkoutPlan>(
                predicate: #Predicate<WorkoutPlan> { plan in
                    plan.isActive == true
                }
            )
            
            let activePlans = try modelContext.fetch(activeDescriptor)
            for plan in activePlans {
                plan.isActive = false
                AppLogger.info("[LibraryViewModel.activatePlan] Deactivated existing plan: \(plan.customName)", category: "LibraryViewModel")
            }
            
            // Save deactivation changes first to prevent conflicts
            if !activePlans.isEmpty {
                try modelContext.save()
                AppLogger.info("[LibraryViewModel.activatePlan] Saved deactivation changes", category: "LibraryViewModel")
            }
            
            // Create new active plan with validated data
            let trimmedName = customName.trimmingCharacters(in: .whitespacesAndNewlines)
            let finalName = trimmedName.isEmpty ? "New Plan" : trimmedName
            
            let newPlan = WorkoutPlan(
                customName: finalName,
                isActive: true,
                startedAt: startDate,
                durationWeeks: 8,
                template: template
            )
            
            // Ensure template relationship is properly set
            newPlan.template = template
            
            modelContext.insert(newPlan)
            try modelContext.save()
            
            activePlanID = newPlan.id
            
            // Refresh the workout plans list to update the UI
            loadWorkoutPlans()
            
            AppLogger.info("[LibraryViewModel.activatePlan] Successfully activated plan: \(finalName)", category: "LibraryViewModel")
            AppLogger.info("[LibraryViewModel.activatePlan] Plan ID: \(newPlan.id), Template: \(template.name)", category: "LibraryViewModel")
            
        } catch {
            AppLogger.error("[LibraryViewModel.activatePlan] Error: \(error.localizedDescription)", category: "LibraryViewModel", error: error)
            AppLogger.error("[LibraryViewModel.activatePlan] Template ID: \(templateID), Custom Name: '\(customName)'", category: "LibraryViewModel")
            AppLogger.error("[LibraryViewModel.activatePlan] Stack trace: \(Thread.callStackSymbols)", category: "LibraryViewModel")
            self.error = error
        }
    }
    
    private func deactivatePlan() {
        AppLogger.debug("[LibraryViewModel.deactivatePlan] Deactivating current plan", category: "LibraryViewModel")
        
        guard let currentActivePlanID = activePlanID,
              let currentPlan = fetchActivePlan(with: currentActivePlanID) else {
            AppLogger.error("[LibraryViewModel.deactivatePlan] No active plan to deactivate", category: "LibraryViewModel")
            error = LibraryError.noActivePlan
            return
        }
        
        do {
            currentPlan.isActive = false
            try modelContext.save()
            
            activePlanID = nil
            
            // Refresh the workout plans list to update the UI
            loadWorkoutPlans()
            
            AppLogger.info("[LibraryViewModel.deactivatePlan] Successfully deactivated plan: \(currentPlan.customName)", category: "LibraryViewModel")
            
        } catch {
            AppLogger.error("[LibraryViewModel.deactivatePlan] Error: \(error.localizedDescription)", category: "LibraryViewModel", error: error)
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
            AppLogger.error("[LibraryViewModel.fetchActivePlan] Error: \(error.localizedDescription)", category: "LibraryViewModel", error: error)
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
    
    // MARK: - JSON Import Methods
    func importExercises(from jsonData: Data) throws {
        AppLogger.debug("[LibraryViewModel.importExercises] Starting JSON import", category: "LibraryViewModel")
        importErrorMessage = nil
        
        do {
            let decoder = JSONDecoder()
            let exercises = try decoder.decode([Exercise].self, from: jsonData)
            
            var importedCount = 0
            for exercise in exercises {
                // Check for duplicates by name
                if !exerciseCatalog.contains(where: { $0.name.lowercased() == exercise.name.lowercased() }) {
                    let newExercise = Exercise(
                        name: exercise.name,
                        category: exercise.category,
                        instructions: exercise.instructions,
                        mediaAssetID: exercise.mediaAssetID
                    )
                    modelContext.insert(newExercise)
                    _cachedExercises.append(newExercise)
                    importedCount += 1
                } else {
                    AppLogger.info("[LibraryViewModel.importExercises] Skipping duplicate exercise: \(exercise.name)", category: "LibraryViewModel")
                }
            }
            
            try modelContext.save()
            _cachedExercises.sort { $0.name < $1.name }
            exerciseCatalog = _cachedExercises // Update published property to trigger UI updates
            
            AppLogger.info("[LibraryViewModel.importExercises] Successfully imported \(importedCount) exercises (skipped \(exercises.count - importedCount) duplicates)", category: "LibraryViewModel")
            
        } catch let decodingError as DecodingError {
            let errorMessage = "JSON format error: \(decodingError.localizedDescription)"
            AppLogger.error("[LibraryViewModel.importExercises] Decoding error: \(errorMessage)", category: "LibraryViewModel")
            importErrorMessage = errorMessage
            throw decodingError
        } catch {
            let errorMessage = "Import failed: \(error.localizedDescription)"
            AppLogger.error("[LibraryViewModel.importExercises] Error: \(errorMessage)", category: "LibraryViewModel")
            importErrorMessage = errorMessage
            throw error
        }
    }
    
    func createWorkoutTemplate(name: String) {
        AppLogger.debug("[LibraryViewModel.createWorkoutTemplate] Creating template: \(name)", category: "LibraryViewModel")
        handleIntent(.createTemplate(name: name, summary: ""))
    }
    
    func createPlan(from template: WorkoutTemplate) {
        AppLogger.debug("[LibraryViewModel.createPlan] Creating plan from template: \(template.name)", category: "LibraryViewModel")
        let planName = "\(template.name) Plan"
        handleIntent(.activatePlan(templateID: template.id, customName: planName, startDate: Date()))
    }
    
    func deleteExercise(_ exercise: Exercise) {
        AppLogger.debug("[LibraryViewModel.deleteExercise] Deleting exercise: \(exercise.name)", category: "LibraryViewModel")
        handleIntent(.deleteExercise(id: exercise.id))
    }
    
    func deleteTemplate(_ template: WorkoutTemplate) {
        AppLogger.debug("[LibraryViewModel.deleteTemplate] Deleting template: \(template.name)", category: "LibraryViewModel")
        handleIntent(.deleteTemplate(id: template.id))
    }
    
    func updateTemplate(_ template: WorkoutTemplate, name: String, summary: String) throws {
        AppLogger.debug("[LibraryViewModel.updateTemplate] Updating template: \(template.name)", category: "LibraryViewModel")
        
        template.name = name
        template.summary = summary
        
        try modelContext.save()
        AppLogger.info("[LibraryViewModel.updateTemplate] Successfully updated template", category: "LibraryViewModel")
        AppLogger.info("[LibraryViewModel] Template updated: \(template.name)", category: "LibraryViewModel")
    }
    
    func createExercise(name: String, category: ExerciseCategory, instructions: String) throws {
        AppLogger.debug("[LibraryViewModel.createExercise] Creating exercise: \(name)", category: "LibraryViewModel")
        let newExercise = Exercise(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            instructions: instructions
        )
        
        modelContext.insert(newExercise)
        try modelContext.save()
        
        // Update cache with new exercise
        _cachedExercises.append(newExercise)
        _cachedExercises.sort { $0.name < $1.name }
        exerciseCatalog = _cachedExercises // Update published property to trigger UI updates
        AppLogger.info("Successfully created exercise", category: "LibraryViewModel.createExercise")
    }
    
    func updateExercise(_ exercise: Exercise, name: String, category: ExerciseCategory, instructions: String) throws {
        AppLogger.debug("[LibraryViewModel.updateExercise] Updating exercise: \(exercise.name)", category: "LibraryViewModel")
        exercise.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        exercise.category = category
        exercise.instructions = instructions
        
        try modelContext.save()
        
        // Update cache to reflect changes
        _cachedExercises.sort { $0.name < $1.name }
        exerciseCatalog = _cachedExercises // Update published property to trigger UI updates
        AppLogger.info("[LibraryViewModel.updateExercise] Successfully updated exercise", category: "LibraryViewModel")
    }
    
    // MARK: - Template Detail Methods
    func toggleRestDay(for dayTemplate: DayTemplate) {
        AppLogger.debug("[LibraryViewModel.toggleRestDay] Toggling rest day for \(dayTemplate.weekday)", category: "LibraryViewModel")
        do {
            dayTemplate.isRest.toggle()
            try modelContext.save()
            AppLogger.info("[LibraryViewModel.toggleRestDay] Successfully toggled rest day", category: "LibraryViewModel")
        } catch {
            AppLogger.error("[LibraryViewModel.toggleRestDay] Error: \(error.localizedDescription)", category: "LibraryViewModel", error: error)
            self.error = error
        }
    }
    
    func addExercises(_ exercises: [Exercise], to dayTemplate: DayTemplate) {
        AppLogger.debug("[LibraryViewModel.addExercises] Adding \(exercises.count) exercises to \(dayTemplate.weekday)", category: "LibraryViewModel")
        do {
            for exercise in exercises {
                let exerciseTemplate = ExerciseTemplate(
                    exercise: exercise,
                    setCount: 3, // Default values
                    reps: 10,
                    weight: nil,
                    position: Double(dayTemplate.exerciseTemplates.count + 1),
                    dayTemplate: dayTemplate
                )
                modelContext.insert(exerciseTemplate)
                dayTemplate.exerciseTemplates.append(exerciseTemplate)
            }
            try modelContext.save()
            AppLogger.info("[LibraryViewModel.addExercises] Successfully added exercises", category: "LibraryViewModel")
        } catch {
            AppLogger.error("[LibraryViewModel.addExercises] Error: \(error.localizedDescription)", category: "LibraryViewModel", error: error)
            self.error = error
        }
    }
    
    func updateExerciseTemplate(_ exerciseTemplate: ExerciseTemplate, setCount: Int, reps: Int, weight: Double?, rest: TimeInterval, supersetID: UUID?) {
        AppLogger.debug("[LibraryViewModel.updateExerciseTemplate] Updating exercise template for \(exerciseTemplate.exercise.name)", category: "LibraryViewModel")
        do {
            exerciseTemplate.setCount = setCount
            exerciseTemplate.reps = reps
            exerciseTemplate.weight = weight
            exerciseTemplate.supersetID = supersetID
            // Note: rest duration would need to be added to ExerciseTemplate model
            try modelContext.save()
            AppLogger.info("[LibraryViewModel.updateExerciseTemplate] Successfully updated exercise template", category: "LibraryViewModel")
        } catch {
            AppLogger.error("[LibraryViewModel.updateExerciseTemplate] Error: \(error.localizedDescription)", category: "LibraryViewModel", error: error)
            self.error = error
        }
    }
    
    // MARK: - Workout Plan Editing Methods
    func updateWorkoutPlan(_ plan: WorkoutPlan, customName: String, durationWeeks: Int, isActive: Bool, notes: String = "") throws {
        AppLogger.debug("[LibraryViewModel.updateWorkoutPlan] Updating plan: \(plan.customName)", category: "LibraryViewModel")
        
        // If setting this plan to active, deactivate all other plans first
        if isActive && !plan.isActive {
            let activeDescriptor = FetchDescriptor<WorkoutPlan>(
                predicate: #Predicate<WorkoutPlan> { existingPlan in
                    existingPlan.isActive == true
                }
            )
            
            do {
                let activePlans = try modelContext.fetch(activeDescriptor)
                for activePlan in activePlans {
                    activePlan.isActive = false
                }
            } catch {
                AppLogger.error("[LibraryViewModel.updateWorkoutPlan] Error deactivating existing plans: \(error.localizedDescription)", category: "LibraryViewModel", error: error)
                throw error
            }
        }
        
        plan.customName = customName.trimmingCharacters(in: .whitespacesAndNewlines)
        plan.durationWeeks = max(durationWeeks, 1) // Ensure minimum 1 week
        plan.isActive = isActive
        plan.notes = notes
        
        // Set endedAt when plan becomes inactive, clear when reactivated
        if !isActive && plan.endedAt == nil {
            plan.endedAt = Date()
        } else if isActive {
            plan.endedAt = nil
        }
        
        try modelContext.save()
        AppLogger.info("[LibraryViewModel.updateWorkoutPlan] Successfully updated plan", category: "LibraryViewModel")
        AppLogger.info("[LibraryViewModel] Plan updated: \(plan.customName) - Active: \(plan.isActive) - Duration: \(plan.durationWeeks) weeks - Completion: \(plan.completionPercentage)%", category: "LibraryViewModel")
    }
    
    // Convenience method for the plan editor
    func savePlan(_ plan: WorkoutPlan) {
        do {
            try updateWorkoutPlan(
                plan,
                customName: plan.customName,
                durationWeeks: plan.durationWeeks,
                isActive: plan.isActive,
                notes: plan.notes
            )
        } catch {
            AppLogger.error("[LibraryViewModel.savePlan] Error saving plan: \(error.localizedDescription)", category: "LibraryViewModel", error: error)
            self.error = error
        }
    }
    
    // Convenience method for the plan editor
    func deletePlan(_ plan: WorkoutPlan) {
        do {
            try deleteWorkoutPlan(plan)
        } catch {
            AppLogger.error("[LibraryViewModel.deletePlan] Error deleting plan: \(error.localizedDescription)", category: "LibraryViewModel", error: error)
            self.error = error
        }
    }
    
    func deleteWorkoutPlan(_ plan: WorkoutPlan) throws {
        AppLogger.debug("[LibraryViewModel.deleteWorkoutPlan] Deleting plan: \(plan.customName)", category: "LibraryViewModel")
        
        modelContext.delete(plan)
        try modelContext.save()
        
        // Refresh the workout plans list to update the UI
        loadWorkoutPlans()
        
        AppLogger.info("[LibraryViewModel.deleteWorkoutPlan] Successfully deleted plan", category: "LibraryViewModel")
    }
    
    // MARK: - JSON Import Methods
    func importWorkoutTemplate(from dto: WorkoutTemplateImportDTO) throws -> Int {
        AppLogger.debug("[LibraryViewModel.importWorkoutTemplate] Starting import of template: \(dto.name)", category: "LibraryViewModel")
        
        // Check for existing template with same name
        if workoutTemplates.contains(where: { $0.name == dto.name }) {
            throw ImportError.duplicateTemplate(dto.name)
        }
        
        // Create the workout template with auto-generated UUID
        let template = WorkoutTemplate(
            id: UUID(), // Always auto-generate new UUID
            name: dto.name,
            summary: dto.summary,
            createdAt: dto.createdAt ?? Date()
        )
        
        modelContext.insert(template)
        
        // Create a set of weekdays from the imported data
        let importedWeekdays = Set(dto.days.compactMap { $0.weekday })
        
        // Create superset ID mapping for this template to maintain grouping
        var supersetIDMapping: [Int: UUID] = [:]
        
        // Process imported days
        for dayDTO in dto.days {
            AppLogger.debug("[LibraryViewModel.importWorkoutTemplate] Processing day: \(dayDTO.name)", category: "LibraryViewModel")
            
            // Get weekday from either dayName or dayIndex
            guard let weekday = dayDTO.weekday else {
                if let dayName = dayDTO.dayName {
                    throw ImportError.invalidDayName(dayName)
                } else if let dayIndex = dayDTO.dayIndex {
                    throw ImportError.invalidDayIndex(dayIndex)
                } else {
                    throw ImportError.missingDayIdentifier
                }
            }
            
            let dayTemplate = DayTemplate(
                weekday: weekday,
                isRest: false,
                notes: "",
                workoutTemplate: template
            )
            
            modelContext.insert(dayTemplate)
            template.dayTemplates.append(dayTemplate)
            
            // Process exercises for this day
            for (index, exerciseDTO) in dayDTO.exercises.enumerated() {
                AppLogger.debug("[LibraryViewModel.importWorkoutTemplate] Processing exercise: \(exerciseDTO.name)", category: "LibraryViewModel")
                
                // Find or create the exercise with full details from DTO
                let exercise = try findOrCreateExercise(
                    name: exerciseDTO.name,
                    category: exerciseDTO.category,
                    instructions: exerciseDTO.instructions,
                    mediaAssetID: exerciseDTO.mediaAssetID
                )
                
                // Handle superset grouping - create or reuse UUID for each superset group
                var supersetID: UUID? = nil
                if let supersetGroup = exerciseDTO.supersetGroup {
                    if let existingID = supersetIDMapping[supersetGroup] {
                        // Reuse existing UUID for this superset group
                        supersetID = existingID
                    } else {
                        // Create new UUID for this superset group and store it
                        let newID = UUID()
                        supersetIDMapping[supersetGroup] = newID
                        supersetID = newID
                    }
                    AppLogger.debug("[LibraryViewModel.importWorkoutTemplate] Assigned superset group \(supersetGroup) to UUID: \(supersetID!)", category: "LibraryViewModel")
                }
                
                // Create exercise template with proper superset ID
                let exerciseTemplate = ExerciseTemplate(
                    id: UUID(), // Always auto-generate new UUID
                    exercise: exercise,
                    setCount: exerciseDTO.sets,
                    reps: exerciseDTO.reps,
                    weight: exerciseDTO.weight,
                    position: Double(index + 1),
                    supersetID: supersetID,
                    dayTemplate: dayTemplate
                )
                
                modelContext.insert(exerciseTemplate)
                dayTemplate.exerciseTemplates.append(exerciseTemplate)
            }
        }
        
        // Create rest days for missing weekdays
        for weekday in Weekday.allCases {
            if !importedWeekdays.contains(weekday) {
                AppLogger.debug("Creating rest day for weekday: \(weekday.fullName)", category: "LibraryViewModel.importWorkoutTemplate")
                
                let restDayTemplate = DayTemplate(
                    weekday: weekday,
                    isRest: true,
                    notes: "Rest day (auto-generated during import)",
                    workoutTemplate: template
                )
                
                modelContext.insert(restDayTemplate)
                template.dayTemplates.append(restDayTemplate)
                
                AppLogger.info("Created rest day for \(weekday.fullName)", category: "LibraryViewModel.importWorkoutTemplate")
            }
        }
        
        // Save everything
        try modelContext.save()
        
        // Update local state
        templates.insert(template, at: 0)
        
        AppLogger.info("Successfully imported template: \(dto.name)", category: "LibraryViewModel.importWorkoutTemplate")
        return 1
    }
    
    private func findOrCreateExercise(
        name: String,
        category: ExerciseCategory? = nil,
        instructions: String? = nil,
        mediaAssetID: String? = nil
    ) throws -> Exercise {
        AppLogger.debug("Looking for exercise: \(name)", category: "LibraryViewModel.findOrCreateExercise")
        
        // First, try to find existing exercise from cache
        if let existingExercise = _cachedExercises.first(where: { $0.name.lowercased() == name.lowercased() }) {
            AppLogger.info("Found existing exercise: \(name)", category: "LibraryViewModel.findOrCreateExercise")
            
            // Update existing exercise with new information if provided
            if let instructions = instructions, !instructions.isEmpty {
                existingExercise.instructions = instructions
                AppLogger.debug("Updated instructions for existing exercise: \(name)", category: "LibraryViewModel.findOrCreateExercise")
            }
            
            if let category = category {
                existingExercise.category = category
                AppLogger.debug("Updated category for existing exercise: \(name)", category: "LibraryViewModel.findOrCreateExercise")
            }
            
            if let mediaAssetID = mediaAssetID {
                existingExercise.mediaAssetID = mediaAssetID
                AppLogger.debug("Updated mediaAssetID for existing exercise: \(name)", category: "LibraryViewModel.findOrCreateExercise")
            }
            
            return existingExercise
        }
        
        // Create new exercise with provided details or defaults
        AppLogger.debug("Creating new exercise: \(name)", category: "LibraryViewModel.findOrCreateExercise")
        let newExercise = Exercise(
            name: name,
            category: category ?? .strength, // Use provided category or default
            instructions: instructions ?? "Exercise imported from JSON template",
            mediaAssetID: mediaAssetID
        )
        
        modelContext.insert(newExercise)
        _cachedExercises.append(newExercise)
        _cachedExercises.sort { $0.name < $1.name }
        exerciseCatalog = _cachedExercises // Update published property to trigger UI updates
        
        AppLogger.info("Created new exercise: \(name)", category: "LibraryViewModel.findOrCreateExercise")
        return newExercise
    }
}

// MARK: - Supporting Types

enum LibrarySegment: CaseIterable {
    case exercises
    case workouts
    
    var title: String {
        switch self {
        case .exercises:
            return "Exercises"
        case .workouts:
            return "Workouts"
        }
    }
}

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

 