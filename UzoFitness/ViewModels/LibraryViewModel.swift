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
    @Published var selectedSegment: LibrarySegment = .exercises
    @Published var importErrorMessage: String?
    
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
    
    // Convenience properties for the UI
    var exercises: [Exercise] {
        sortedExercises
    }
    
    var workoutTemplates: [WorkoutTemplate] {
        sortedTemplates
    }
    
    var workoutPlans: [WorkoutPlan] {
        do {
            let descriptor = FetchDescriptor<WorkoutPlan>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            return try modelContext.fetch(descriptor)
        } catch {
            print("❌ [LibraryViewModel.workoutPlans] Error: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Private Properties
    private let modelContext: ModelContext
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Methods for View Access
    func deleteExerciseTemplate(_ exerciseTemplate: ExerciseTemplate) {
        print("🔄 [LibraryViewModel.deleteExerciseTemplate] Deleting exercise template for \(exerciseTemplate.exercise.name)")
        
        // Remove from day template
        exerciseTemplate.dayTemplate?.exerciseTemplates.removeAll { $0.id == exerciseTemplate.id }
        
        // Delete from context
        modelContext.delete(exerciseTemplate)
        
        do {
            try modelContext.save()
            print("✅ [LibraryViewModel.deleteExerciseTemplate] Successfully deleted exercise template")
        } catch {
            print("❌ [LibraryViewModel.deleteExerciseTemplate] Error: \(error.localizedDescription)")
            self.error = error
        }
    }
    
    func reorderExerciseTemplates(in dayTemplate: DayTemplate, from source: IndexSet, to destination: Int) {
        print("🔄 [LibraryViewModel.reorderExerciseTemplates] Reordering exercises in \(dayTemplate.weekday)")
        
        let sortedExercises = dayTemplate.exerciseTemplates.sorted(by: { $0.position < $1.position })
        var reorderedExercises = sortedExercises
        reorderedExercises.move(fromOffsets: source, toOffset: destination)
        
        // Update positions
        for (index, exerciseTemplate) in reorderedExercises.enumerated() {
            exerciseTemplate.position = Double(index + 1)
        }
        
        do {
            try modelContext.save()
            print("✅ [LibraryViewModel.reorderExerciseTemplates] Successfully reordered exercises")
        } catch {
            print("❌ [LibraryViewModel.reorderExerciseTemplates] Error: \(error.localizedDescription)")
            self.error = error
        }
    }
    
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
            // Deactivate any existing active plans first
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
            
            // Save deactivation changes first to prevent conflicts
            if !activePlans.isEmpty {
                try modelContext.save()
                print("✅ [LibraryViewModel.activatePlan] Saved deactivation changes")
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
            
            print("✅ [LibraryViewModel.activatePlan] Successfully activated plan: \(finalName)")
            print("📊 [LibraryViewModel.activatePlan] Plan ID: \(newPlan.id), Template: \(template.name)")
            
        } catch {
            print("❌ [LibraryViewModel.activatePlan] Error: \(error.localizedDescription)")
            print("❌ [LibraryViewModel.activatePlan] Template ID: \(templateID), Custom Name: '\(customName)'")
            print("❌ [LibraryViewModel.activatePlan] Stack trace: \(Thread.callStackSymbols)")
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
    
    // MARK: - JSON Import Methods
    func importExercises(from jsonData: Data) throws {
        print("🔄 [LibraryViewModel.importExercises] Starting JSON import")
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
                    exerciseCatalog.append(newExercise)
                    importedCount += 1
                } else {
                    print("📊 [LibraryViewModel.importExercises] Skipping duplicate exercise: \(exercise.name)")
                }
            }
            
            try modelContext.save()
            exerciseCatalog.sort { $0.name < $1.name }
            
            print("✅ [LibraryViewModel.importExercises] Successfully imported \(importedCount) exercises (skipped \(exercises.count - importedCount) duplicates)")
            
        } catch let decodingError as DecodingError {
            let errorMessage = "JSON format error: \(decodingError.localizedDescription)"
            print("❌ [LibraryViewModel.importExercises] Decoding error: \(errorMessage)")
            importErrorMessage = errorMessage
            throw decodingError
        } catch {
            let errorMessage = "Import failed: \(error.localizedDescription)"
            print("❌ [LibraryViewModel.importExercises] Error: \(errorMessage)")
            importErrorMessage = errorMessage
            throw error
        }
    }
    
    func createWorkoutTemplate(name: String) {
        print("🔄 [LibraryViewModel.createWorkoutTemplate] Creating template: \(name)")
        handleIntent(.createTemplate(name: name, summary: ""))
    }
    
    func createPlan(from template: WorkoutTemplate) {
        print("🔄 [LibraryViewModel.createPlan] Creating plan from template: \(template.name)")
        let planName = "\(template.name) Plan"
        handleIntent(.activatePlan(templateID: template.id, customName: planName, startDate: Date()))
    }
    
    func deleteExercise(_ exercise: Exercise) {
        print("🔄 [LibraryViewModel.deleteExercise] Deleting exercise: \(exercise.name)")
        handleIntent(.deleteExercise(id: exercise.id))
    }
    
    func deleteTemplate(_ template: WorkoutTemplate) {
        print("🔄 [LibraryViewModel.deleteTemplate] Deleting template: \(template.name)")
        handleIntent(.deleteTemplate(id: template.id))
    }
    
    func updateTemplate(_ template: WorkoutTemplate, name: String, summary: String) throws {
        print("🔄 [LibraryViewModel.updateTemplate] Updating template: \(template.name)")
        
        template.name = name
        template.summary = summary
        
        try modelContext.save()
        print("✅ [LibraryViewModel.updateTemplate] Successfully updated template")
        print("📊 [LibraryViewModel] Template updated: \(template.name)")
    }
    
    func createExercise(name: String, category: ExerciseCategory, instructions: String) throws {
        print("🔄 [LibraryViewModel.createExercise] Creating exercise: \(name)")
        let newExercise = Exercise(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            instructions: instructions
        )
        
        modelContext.insert(newExercise)
        try modelContext.save()
        exerciseCatalog.append(newExercise)
        exerciseCatalog.sort { $0.name < $1.name }
        print("✅ [LibraryViewModel.createExercise] Successfully created exercise")
    }
    
    func updateExercise(_ exercise: Exercise, name: String, category: ExerciseCategory, instructions: String) throws {
        print("🔄 [LibraryViewModel.updateExercise] Updating exercise: \(exercise.name)")
        exercise.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        exercise.category = category
        exercise.instructions = instructions
        
        try modelContext.save()
        exerciseCatalog.sort { $0.name < $1.name }
        print("✅ [LibraryViewModel.updateExercise] Successfully updated exercise")
    }
    
    // MARK: - Template Detail Methods
    func toggleRestDay(for dayTemplate: DayTemplate) {
        print("🔄 [LibraryViewModel.toggleRestDay] Toggling rest day for \(dayTemplate.weekday)")
        do {
            dayTemplate.isRest.toggle()
            try modelContext.save()
            print("✅ [LibraryViewModel.toggleRestDay] Successfully toggled rest day")
        } catch {
            print("❌ [LibraryViewModel.toggleRestDay] Error: \(error.localizedDescription)")
            self.error = error
        }
    }
    
    func addExercises(_ exercises: [Exercise], to dayTemplate: DayTemplate) {
        print("🔄 [LibraryViewModel.addExercises] Adding \(exercises.count) exercises to \(dayTemplate.weekday)")
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
            print("✅ [LibraryViewModel.addExercises] Successfully added exercises")
        } catch {
            print("❌ [LibraryViewModel.addExercises] Error: \(error.localizedDescription)")
            self.error = error
        }
    }
    
    func updateExerciseTemplate(_ exerciseTemplate: ExerciseTemplate, setCount: Int, reps: Int, weight: Double?, rest: TimeInterval, supersetID: UUID?) {
        print("🔄 [LibraryViewModel.updateExerciseTemplate] Updating exercise template for \(exerciseTemplate.exercise.name)")
        do {
            exerciseTemplate.setCount = setCount
            exerciseTemplate.reps = reps
            exerciseTemplate.weight = weight
            exerciseTemplate.supersetID = supersetID
            // Note: rest duration would need to be added to ExerciseTemplate model
            try modelContext.save()
            print("✅ [LibraryViewModel.updateExerciseTemplate] Successfully updated exercise template")
        } catch {
            print("❌ [LibraryViewModel.updateExerciseTemplate] Error: \(error.localizedDescription)")
            self.error = error
        }
    }
    
    // MARK: - Workout Plan Editing Methods
    func updateWorkoutPlan(_ plan: WorkoutPlan, customName: String, durationWeeks: Int, isActive: Bool) throws {
        print("🔄 [LibraryViewModel.updateWorkoutPlan] Updating plan: \(plan.customName)")
        
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
                print("❌ [LibraryViewModel.updateWorkoutPlan] Error deactivating existing plans: \(error.localizedDescription)")
                throw error
            }
        }
        
        plan.customName = customName.trimmingCharacters(in: .whitespacesAndNewlines)
        plan.durationWeeks = max(durationWeeks, 1) // Ensure minimum 1 week
        plan.isActive = isActive
        
        try modelContext.save()
        print("✅ [LibraryViewModel.updateWorkoutPlan] Successfully updated plan")
        print("📊 [LibraryViewModel] Plan updated: \(plan.customName) - Active: \(plan.isActive) - Duration: \(plan.durationWeeks) weeks")
    }
    
    func deleteWorkoutPlan(_ plan: WorkoutPlan) throws {
        print("🔄 [LibraryViewModel.deleteWorkoutPlan] Deleting plan: \(plan.customName)")
        
        modelContext.delete(plan)
        try modelContext.save()
        
        print("✅ [LibraryViewModel.deleteWorkoutPlan] Successfully deleted plan")
    }
    
    // MARK: - JSON Import Methods
    func importWorkoutTemplate(from dto: WorkoutTemplateImportDTO) throws -> Int {
        print("🔄 [LibraryViewModel.importWorkoutTemplate] Starting import of template: \(dto.name)")
        
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
        
        // Process days
        for dayDTO in dto.days {
            print("🔄 [LibraryViewModel.importWorkoutTemplate] Processing day: \(dayDTO.name)")
            
            // Map dayIndex to Weekday enum
            guard let weekday = Weekday(rawValue: dayDTO.dayIndex) else {
                throw ImportError.invalidDayIndex(dayDTO.dayIndex)
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
                print("🔄 [LibraryViewModel.importWorkoutTemplate] Processing exercise: \(exerciseDTO.name)")
                
                // Find or create the exercise
                let exercise = try findOrCreateExercise(name: exerciseDTO.name)
                
                // Create exercise template with auto-generated UUID
                let exerciseTemplate = ExerciseTemplate(
                    id: UUID(), // Always auto-generate new UUID
                    exercise: exercise,
                    setCount: exerciseDTO.sets,
                    reps: exerciseDTO.reps,
                    weight: exerciseDTO.weight,
                    position: Double(index + 1),
                    supersetID: exerciseDTO.supersetGroup.map { _ in UUID() }, // Convert superset group to UUID
                    dayTemplate: dayTemplate
                )
                
                modelContext.insert(exerciseTemplate)
                dayTemplate.exerciseTemplates.append(exerciseTemplate)
            }
        }
        
        // Save everything
        try modelContext.save()
        
        // Update local state
        templates.insert(template, at: 0)
        
        print("✅ [LibraryViewModel.importWorkoutTemplate] Successfully imported template: \(dto.name)")
        return 1
    }
    
    private func findOrCreateExercise(name: String) throws -> Exercise {
        print("🔄 [LibraryViewModel.findOrCreateExercise] Looking for exercise: \(name)")
        
        // First, try to find existing exercise
        if let existingExercise = exerciseCatalog.first(where: { $0.name.lowercased() == name.lowercased() }) {
            print("✅ [LibraryViewModel.findOrCreateExercise] Found existing exercise: \(name)")
            return existingExercise
        }
        
        // Create new exercise with default category
        print("🔄 [LibraryViewModel.findOrCreateExercise] Creating new exercise: \(name)")
        let newExercise = Exercise(
            name: name,
            category: .strength, // Default category
            instructions: "Exercise imported from JSON template"
        )
        
        modelContext.insert(newExercise)
        exerciseCatalog.append(newExercise)
        exerciseCatalog.sort { $0.name < $1.name }
        
        print("✅ [LibraryViewModel.findOrCreateExercise] Created new exercise: \(name)")
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

 