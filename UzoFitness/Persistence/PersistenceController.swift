import Foundation
import SwiftData

@MainActor
class PersistenceController: ObservableObject {
    
    // MARK: - Singleton
    static let shared = PersistenceController()
    
    // MARK: - Container & Context
    let container: ModelContainer
    var context: ModelContext { container.mainContext }
    
    // MARK: - Preview Support
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        
        // Add sample data for previews
        controller.addSampleData()
        
        return controller
    }()
    
    // MARK: - Initialization
    init(inMemory: Bool = false) {
        let schema = Schema([
            Exercise.self,
            WorkoutTemplate.self,
            DayTemplate.self,
            ExerciseTemplate.self,
            WorkoutPlan.self,
            WorkoutSession.self,
            SessionExercise.self,
            CompletedSet.self,
            ProgressPhoto.self,
            PerformedExercise.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            allowsSave: true,
            groupContainer: .none,
            cloudKitDatabase: .automatic // Enable CloudKit sync
        )
        
        do {
            AppLogger.info("[PersistenceController.init] Creating ModelContainer with schema", category: "Persistence")
            AppLogger.debug("[PersistenceController.init] Schema includes: \(schema.entities.map { $0.name })", category: "Persistence")
            AppLogger.debug("[PersistenceController.init] In-memory: \(inMemory)", category: "Persistence")
            
            container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
            AppLogger.info("[PersistenceController.init] ModelContainer created successfully", category: "Persistence")
            
            // Configure context
            context.autosaveEnabled = true
            AppLogger.info("[PersistenceController.init] Context configured with autosave enabled", category: "Persistence")
            
        } catch {
            AppLogger.error("[PersistenceController.init] Failed to create ModelContainer", category: "Persistence", error: error)
            AppLogger.error("[PersistenceController.init] Error details: \(error)", category: "Persistence", error: error)
            
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    // MARK: - Save Context
    func save() {
        do {
            try context.save()
        } catch {
            AppLogger.error("Failed to save context", category: "Persistence", error: error)
        }
    }
    
    // MARK: - Generic CRUD Operations
    
    /// Create and insert a new model
    func create<T: PersistentModel & Identified>(_ model: T) {
        context.insert(model)
        save()
    }
    
    /// Fetch all models of a specific type
    func fetch<T: PersistentModel & Identified>(_ type: T.Type) -> [T] {
        do {
            let descriptor = FetchDescriptor<T>()
            return try context.fetch(descriptor)
        } catch {
            AppLogger.error("Failed to fetch \(T.entityName)", category: "Persistence", error: error)
            return []
        }
    }
    
    /// Fetch models with predicate
    func fetch<T: PersistentModel & Identified>(_ type: T.Type, predicate: Predicate<T>? = nil, sortBy: [SortDescriptor<T>] = []) -> [T] {
        do {
            let descriptor = FetchDescriptor<T>(predicate: predicate, sortBy: sortBy)
            return try context.fetch(descriptor)
        } catch {
            AppLogger.error("Failed to fetch \(T.entityName) with predicate", category: "Persistence", error: error)
            return []
        }
    }
    
    /// Delete a model (cascade-safe)
    func delete<T: PersistentModel & Identified>(_ model: T) {
        AppLogger.info("[PersistenceController.delete] Deleting \(T.entityName)", category: "Persistence")
        
        switch model {
        case let session as WorkoutSession:
            AppLogger.debug("[PersistenceController.delete] Cascading deletion for WorkoutSession with \(session.sessionExercises.count) exercises", category: "Persistence")
            for exercise in session.sessionExercises {
                AppLogger.debug("[PersistenceController.delete] Deleting SessionExercise with \(exercise.completedSets.count) sets", category: "Persistence")
                for set in exercise.completedSets {
                    context.delete(set)
                }
                context.delete(exercise)
            }

        case let template as WorkoutTemplate:
            AppLogger.debug("[PersistenceController.delete] Cascading deletion for WorkoutTemplate '\(template.name)' with \(template.dayTemplates.count) days", category: "Persistence")
            for day in template.dayTemplates {
                AppLogger.debug("[PersistenceController.delete] Deleting DayTemplate for \(day.weekday) with \(day.exerciseTemplates.count) exercises", category: "Persistence")
                for exerciseTemplate in day.exerciseTemplates {
                    context.delete(exerciseTemplate)
                }
                context.delete(day)
            }

        case let exercise as SessionExercise:
            AppLogger.debug("[PersistenceController.delete] Cascading deletion for SessionExercise with \(exercise.completedSets.count) sets", category: "Persistence")
            for set in exercise.completedSets {
                context.delete(set)
            }

        default:
            break
        }

        context.delete(model)
        save()
        AppLogger.info("[PersistenceController.delete] Successfully deleted \(T.entityName)", category: "Persistence")
    }
    
    /// Delete multiple models
    func delete<T: PersistentModel & Identified>(_ models: [T]) {
        AppLogger.info("[PersistenceController.delete] Batch deleting \(models.count) \(T.entityName) models", category: "Persistence")
        models.forEach { context.delete($0) }
        save()
        AppLogger.info("[PersistenceController.delete] Successfully deleted \(models.count) \(T.entityName) models", category: "Persistence")
    }
    
    // MARK: - Specific Helper Methods
    
    /// Get active workout plan
    func getActiveWorkoutPlan() -> WorkoutPlan? {
        let predicate = #Predicate<WorkoutPlan> { $0.isActive == true }
        return fetch(WorkoutPlan.self, predicate: predicate).first
    }
    
    /// Get workout sessions for a date range
    func getWorkoutSessions(from startDate: Date, to endDate: Date) -> [WorkoutSession] {
        let predicate = #Predicate<WorkoutSession> { session in
            session.date >= startDate && session.date <= endDate
        }
        let sortBy = [SortDescriptor<WorkoutSession>(\.date, order: .reverse)]
        return fetch(WorkoutSession.self, predicate: predicate, sortBy: sortBy)
    }
    
    /// Get recent workout sessions
    func getRecentWorkoutSessions(limit: Int = 10) -> [WorkoutSession] {
        let sortBy = [SortDescriptor<WorkoutSession>(\.date, order: .reverse)]
        var descriptor = FetchDescriptor<WorkoutSession>(sortBy: sortBy)
        descriptor.fetchLimit = limit
        
        do {
            return try context.fetch(descriptor)
        } catch {
            AppLogger.error("Failed to fetch recent sessions", category: "Persistence", error: error)
            return []
        }
    }
    
    /// Get exercises by category
    func getExercises(by category: ExerciseCategory) -> [Exercise] {
        let predicate = #Predicate<Exercise> { $0.category == category }
        let sortBy = [SortDescriptor<Exercise>(\.name)]
        return fetch(Exercise.self, predicate: predicate, sortBy: sortBy)
    }
    
    /// Get progress photos for a specific angle
    func getProgressPhotos(for angle: PhotoAngle) -> [ProgressPhoto] {
        let predicate = #Predicate<ProgressPhoto> { $0.angle == angle }
        let sortBy = [SortDescriptor<ProgressPhoto>(\.date, order: .reverse)]
        return fetch(ProgressPhoto.self, predicate: predicate, sortBy: sortBy)
    }
    
    /// Calculate total volume for a date range
    func getTotalVolume(from startDate: Date, to endDate: Date) -> Double {
        let sessions = getWorkoutSessions(from: startDate, to: endDate)
        return sessions.reduce(0) { $0 + $1.totalVolume }
    }
    
    // MARK: - Batch Operations
    
    /// Delete all data (useful for testing/reset)
    func deleteAllData() {
        AppLogger.info("[PersistenceController.deleteAllData] Starting deletion of all data", category: "Persistence")
        
        // Delete in order to respect relationships
        let completedSets = fetch(CompletedSet.self)
        let sessionExercises = fetch(SessionExercise.self)
        let workoutSessions = fetch(WorkoutSession.self)
        let exerciseTemplates = fetch(ExerciseTemplate.self)
        let dayTemplates = fetch(DayTemplate.self)
        let workoutPlans = fetch(WorkoutPlan.self)
        let workoutTemplates = fetch(WorkoutTemplate.self)
        let progressPhotos = fetch(ProgressPhoto.self)
        let performedExercises = fetch(PerformedExercise.self)
        let exercises = fetch(Exercise.self)
        
        AppLogger.debug("[PersistenceController.deleteAllData] Deleting \(completedSets.count) CompletedSets", category: "Persistence")
        delete(completedSets)
        
        AppLogger.debug("[PersistenceController.deleteAllData] Deleting \(sessionExercises.count) SessionExercises", category: "Persistence")
        delete(sessionExercises)
        
        AppLogger.debug("[PersistenceController.deleteAllData] Deleting \(workoutSessions.count) WorkoutSessions", category: "Persistence")
        delete(workoutSessions)
        
        AppLogger.debug("[PersistenceController.deleteAllData] Deleting \(exerciseTemplates.count) ExerciseTemplates", category: "Persistence")
        delete(exerciseTemplates)
        
        AppLogger.debug("[PersistenceController.deleteAllData] Deleting \(dayTemplates.count) DayTemplates", category: "Persistence")
        delete(dayTemplates)
        
        AppLogger.debug("[PersistenceController.deleteAllData] Deleting \(workoutPlans.count) WorkoutPlans", category: "Persistence")
        delete(workoutPlans)
        
        AppLogger.debug("[PersistenceController.deleteAllData] Deleting \(workoutTemplates.count) WorkoutTemplates", category: "Persistence")
        delete(workoutTemplates)
        
        AppLogger.debug("[PersistenceController.deleteAllData] Deleting \(progressPhotos.count) ProgressPhotos", category: "Persistence")
        delete(progressPhotos)
        
        AppLogger.debug("[PersistenceController.deleteAllData] Deleting \(performedExercises.count) PerformedExercises", category: "Persistence")
        delete(performedExercises)
        
        AppLogger.debug("[PersistenceController.deleteAllData] Deleting \(exercises.count) Exercises", category: "Persistence")
        delete(exercises)
        
        AppLogger.info("[PersistenceController.deleteAllData] Successfully deleted all data", category: "Persistence")
    }
    
    // MARK: - Sample Data for Previews
    private func addSampleData() {
        // Create sample exercises
        let pushup = Exercise(name: "Push-up", category: .strength, instructions: "Standard push-up exercise")
        let squat = Exercise(name: "Squat", category: .strength, instructions: "Bodyweight squat")
        let plank = Exercise(name: "Plank", category: .strength, instructions: "Hold plank position")
        
        create(pushup)
        create(squat)
        create(plank)
        
        // Create sample workout template
        let template = WorkoutTemplate(name: "Upper Body Blast", summary: "Focus on upper body strength")
        create(template)
        
        // Create sample day template
        let dayTemplate = DayTemplate(weekday: .monday, notes: "Chest and arms day")
        dayTemplate.workoutTemplate = template
        create(dayTemplate)
        
        // Create sample exercise templates
        let pushupTemplate = ExerciseTemplate(exercise: pushup, setCount: 3, reps: 10, position: 1.0)
        pushupTemplate.dayTemplate = dayTemplate
        create(pushupTemplate)
        
        let plankTemplate = ExerciseTemplate(exercise: plank, setCount: 3, reps: 1, weight: nil, position: 2.0)
        plankTemplate.dayTemplate = dayTemplate
        create(plankTemplate)
        
        // Create sample workout plan
        let plan = WorkoutPlan(customName: "My Fitness Journey", template: template)
        create(plan)
        
        // Create sample workout session
        let session = WorkoutSession(date: Date(), title: "Morning Workout", plan: plan)
        create(session)
        
        // Create sample session exercise
        let sessionExercise = SessionExercise(
            exercise: pushup,
            plannedSets: 3,
            plannedReps: 10,
            plannedWeight: nil,
            position: 1.0
        )
        sessionExercise.session = session
        create(sessionExercise)
        
        // Create sample completed sets
        let set1 = CompletedSet(reps: 10, weight: 0)
        let set2 = CompletedSet(reps: 8, weight: 0)
        set1.sessionExercise = sessionExercise
        set2.sessionExercise = sessionExercise
        create(set1)
        create(set2)
    }
}
