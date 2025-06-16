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
            ProgressPhoto.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            allowsSave: true,
            groupContainer: .none,
            cloudKitDatabase: .automatic // Enable CloudKit sync
        )
        
        do {
            container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
            // Configure context
            context.autosaveEnabled = true
            
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    // MARK: - Save Context
    func save() {
        do {
            try context.save()
        } catch {
            print("Failed to save context: \(error)")
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
            print("Failed to fetch \(T.entityName): \(error)")
            return []
        }
    }
    
    /// Fetch models with predicate
    func fetch<T: PersistentModel & Identified>(_ type: T.Type, predicate: Predicate<T>? = nil, sortBy: [SortDescriptor<T>] = []) -> [T] {
        do {
            let descriptor = FetchDescriptor<T>(predicate: predicate, sortBy: sortBy)
            return try context.fetch(descriptor)
        } catch {
            print("Failed to fetch \(T.entityName) with predicate: \(error)")
            return []
        }
    }
    
    /// Delete a model
    func delete<T: PersistentModel & Identified>(_ model: T) {
        context.delete(model)
        save()
    }
    
    /// Delete multiple models
    func delete<T: PersistentModel & Identified>(_ models: [T]) {
        models.forEach { context.delete($0) }
        save()
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
            print("Failed to fetch recent sessions: \(error)")
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
        // Delete in order to respect relationships
        delete(fetch(CompletedSet.self))
        delete(fetch(SessionExercise.self))
        delete(fetch(WorkoutSession.self))
        delete(fetch(ExerciseTemplate.self))
        delete(fetch(DayTemplate.self))
        delete(fetch(WorkoutPlan.self))
        delete(fetch(WorkoutTemplate.self))
        delete(fetch(ProgressPhoto.self))
        delete(fetch(Exercise.self))
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
        var dayTemplate = DayTemplate(weekday: .monday, notes: "Chest and arms day")
        dayTemplate.workoutTemplate = template
        create(dayTemplate)
        
        // Create sample exercise templates
        var pushupTemplate = ExerciseTemplate(exercise: pushup, setCount: 3, reps: 10, position: 1.0)
        pushupTemplate.dayTemplate = dayTemplate
        create(pushupTemplate)
        
        var plankTemplate = ExerciseTemplate(exercise: plank, setCount: 3, reps: 1, weight: nil, position: 2.0)
        plankTemplate.dayTemplate = dayTemplate
        create(plankTemplate)
        
        // Create sample workout plan
        let plan = WorkoutPlan(customName: "My Fitness Journey", template: template)
        create(plan)
        
        // Create sample workout session
        let session = WorkoutSession(date: Date(), title: "Morning Workout", plan: plan)
        create(session)
        
        // Create sample session exercise
        var sessionExercise = SessionExercise(
            exercise: pushup,
            plannedSets: 3,
            plannedReps: 10,
            plannedWeight: nil,
            position: 1.0
        )
        sessionExercise.session = session
        create(sessionExercise)
        
        // Create sample completed sets
        var set1 = CompletedSet(reps: 10, weight: 0)
        var set2 = CompletedSet(reps: 8, weight: 0)
        set1.sessionExercise = sessionExercise
        set2.sessionExercise = sessionExercise
        create(set1)
        create(set2)
    }
}
