import Foundation
import SwiftData
import UzoFitnessCore
@testable import UzoFitness

/// Test data factories for creating realistic test data
/// Provides factory methods for all model types with various configurations
@MainActor
public class TestDataFactories {
    
    // MARK: - Exercise Factory
    
    /// Create a realistic exercise with specified parameters
    public static func createExercise(
        name: String,
        category: ExerciseCategory,
        instructions: String? = nil,
        equipment: String? = nil,
        muscleGroups: [String] = []
    ) -> Exercise {
        let exercise = Exercise(
            name: name,
            category: category,
            instructions: instructions ?? "Standard \(name.lowercased()) exercise"
        )
        
        // Note: Equipment and muscleGroups properties would need to be added to Exercise model
        // For now, we'll just create the basic exercise
        
        return exercise
    }
    
    /// Create a collection of common exercises
    public static func createCommonExercises() -> [Exercise] {
        return [
            createExercise(name: "Push-up", category: .strength, instructions: "Standard push-up exercise"),
            createExercise(name: "Pull-up", category: .strength, instructions: "Pull-up exercise"),
            createExercise(name: "Squat", category: .strength, instructions: "Bodyweight squat"),
            createExercise(name: "Deadlift", category: .strength, instructions: "Barbell deadlift"),
            createExercise(name: "Bench Press", category: .strength, instructions: "Barbell bench press"),
            createExercise(name: "Overhead Press", category: .strength, instructions: "Barbell overhead press"),
            createExercise(name: "Row", category: .strength, instructions: "Barbell row"),
            createExercise(name: "Plank", category: .strength, instructions: "Hold plank position"),
            createExercise(name: "Burpee", category: .cardio, instructions: "Full burpee exercise"),
            createExercise(name: "Mountain Climber", category: .cardio, instructions: "Mountain climber exercise"),
            createExercise(name: "Jumping Jack", category: .cardio, instructions: "Jumping jack exercise"),
            createExercise(name: "Lunge", category: .strength, instructions: "Walking lunge"),
            createExercise(name: "Dip", category: .strength, instructions: "Tricep dip"),
            createExercise(name: "Crunch", category: .strength, instructions: "Abdominal crunch"),
            createExercise(name: "Leg Press", category: .strength, instructions: "Machine leg press")
        ]
    }
    
    // MARK: - WorkoutTemplate Factory
    
    /// Create a realistic workout template
    public static func createWorkoutTemplate(
        name: String,
        summary: String,
        difficulty: String = "Intermediate",
        estimatedDuration: TimeInterval = 3600 // 1 hour
    ) -> WorkoutTemplate {
        return WorkoutTemplate(name: name, summary: summary)
    }
    
    /// Create common workout templates
    public static func createCommonWorkoutTemplates() -> [WorkoutTemplate] {
        return [
            createWorkoutTemplate(
                name: "Upper Body Blast",
                summary: "Focus on chest, shoulders, and arms"
            ),
            createWorkoutTemplate(
                name: "Lower Body Power",
                summary: "Build strength in legs and glutes"
            ),
            createWorkoutTemplate(
                name: "Full Body Circuit",
                summary: "Complete body workout with minimal rest"
            ),
            createWorkoutTemplate(
                name: "Cardio HIIT",
                summary: "High-intensity interval training"
            ),
            createWorkoutTemplate(
                name: "Core Crusher",
                summary: "Intensive core and abdominal workout"
            )
        ]
    }
    
    // MARK: - WorkoutSession Factory
    
    /// Create a realistic workout session
    public static func createWorkoutSession(
        date: Date = Date(),
        title: String,
        plan: WorkoutPlan? = nil,
        duration: TimeInterval? = nil,
        notes: String? = nil
    ) -> WorkoutSession {
        let session = WorkoutSession(date: date, title: title, plan: plan)
        
        // Note: Duration and notes properties would need to be added to WorkoutSession model
        // For now, we'll just create the basic session
        
        return session
    }
    
    /// Create workout sessions for a date range
    public static func createWorkoutSessionsForDateRange(
        from startDate: Date,
        to endDate: Date,
        plan: WorkoutPlan? = nil
    ) -> [WorkoutSession] {
        var sessions: [WorkoutSession] = []
        let calendar = Calendar.current
        var currentDate = startDate
        
        while currentDate <= endDate {
            // Create sessions every other day
            if calendar.component(.weekday, from: currentDate) % 2 == 1 {
                let session = createWorkoutSession(
                    date: currentDate,
                    title: "Workout \(sessions.count + 1)",
                    plan: plan
                )
                sessions.append(session)
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return sessions
    }
    
    // MARK: - SessionExercise Factory
    
    /// Create a realistic session exercise
    public static func createSessionExercise(
        exercise: Exercise,
        plannedSets: Int,
        plannedReps: Int,
        plannedWeight: Double? = nil,
        position: Double = 1.0,
        session: WorkoutSession? = nil
    ) -> SessionExercise {
        let sessionExercise = SessionExercise(
            exercise: exercise,
            plannedSets: plannedSets,
            plannedReps: plannedReps,
            plannedWeight: plannedWeight,
            position: position
        )
        sessionExercise.session = session
        return sessionExercise
    }
    
    /// Create session exercises for a workout session
    public static func createSessionExercisesForWorkout(
        session: WorkoutSession,
        exercises: [Exercise]
    ) -> [SessionExercise] {
        return exercises.enumerated().map { index, exercise in
            let plannedSets = 3
            let plannedReps = 10
            let plannedWeight: Double? = exercise.category == .strength ? 135.0 : nil
            let position = Double(index + 1)
            
            return createSessionExercise(
                exercise: exercise,
                plannedSets: plannedSets,
                plannedReps: plannedReps,
                plannedWeight: plannedWeight,
                position: position,
                session: session
            )
        }
    }
    
    // MARK: - CompletedSet Factory
    
    /// Create a realistic completed set
    public static func createCompletedSet(
        reps: Int,
        weight: Double = 0,
        sessionExercise: SessionExercise? = nil,
        restTime: TimeInterval? = nil
    ) -> CompletedSet {
        let set = CompletedSet(reps: reps, weight: weight)
        set.sessionExercise = sessionExercise
        
        // Note: RestTime property would need to be added to CompletedSet model
        // For now, we'll just create the basic set
        
        return set
    }
    
    /// Create completed sets for a session exercise
    public static func createCompletedSetsForSessionExercise(
        sessionExercise: SessionExercise,
        setCount: Int? = nil
    ) -> [CompletedSet] {
        let sets = setCount ?? sessionExercise.plannedSets
        var completedSets: [CompletedSet] = []
        
        for setIndex in 1...sets {
            let reps = sessionExercise.plannedReps
            let weight = sessionExercise.plannedWeight ?? 0
            
            // Simulate fatigue by reducing reps in later sets
            let adjustedReps = max(reps - (setIndex - 1), reps / 2)
            
            let completedSet = createCompletedSet(
                reps: adjustedReps,
                weight: weight,
                sessionExercise: sessionExercise
            )
            completedSets.append(completedSet)
        }
        
        return completedSets
    }
    
    // MARK: - ProgressPhoto Factory
    
    /// Create a realistic progress photo
    public static func createProgressPhoto(
        date: Date = Date(),
        angle: PhotoAngle,
        assetIdentifier: String = "progress-photo-\(UUID().uuidString)",
        notes: String? = nil,
        weight: Double? = nil,
        bodyFatPercentage: Double? = nil
    ) -> ProgressPhoto {
        let photo = ProgressPhoto(
            date: date,
            angle: angle,
            assetIdentifier: assetIdentifier,
            notes: notes ?? "Progress photo - \(angle.rawValue)",
            manualWeight: weight
        )
        
        return photo
    }
    
    /// Create progress photos for a date range
    public static func createProgressPhotosForDateRange(
        from startDate: Date,
        to endDate: Date,
        angles: [PhotoAngle] = [.front, .side, .back]
    ) -> [ProgressPhoto] {
        var photos: [ProgressPhoto] = []
        let calendar = Calendar.current
        var currentDate = startDate
        
        while currentDate <= endDate {
            // Create photos weekly
            if calendar.component(.weekday, from: currentDate) == 1 { // Sunday
                for angle in angles {
                    let photo = createProgressPhoto(
                        date: currentDate,
                        angle: angle,
                        notes: "Weekly progress - \(angle.rawValue)"
                    )
                    photos.append(photo)
                }
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return photos
    }
    
    // MARK: - ExerciseTemplate Factory
    
    /// Create a realistic exercise template
    public static func createExerciseTemplate(
        exercise: Exercise,
        setCount: Int,
        reps: Int,
        weight: Double? = nil,
        position: Double = 1.0,
        dayTemplate: DayTemplate? = nil,
        restTime: TimeInterval = 90
    ) -> ExerciseTemplate {
        let template = ExerciseTemplate(
            exercise: exercise,
            setCount: setCount,
            reps: reps,
            weight: weight,
            position: position
        )
        template.dayTemplate = dayTemplate
        return template
    }
    
    /// Create exercise templates for a day template
    public static func createExerciseTemplatesForDay(
        dayTemplate: DayTemplate,
        exercises: [Exercise]
    ) -> [ExerciseTemplate] {
        return exercises.enumerated().map { index, exercise in
            let setCount = 3
            let reps = 10
            let weight: Double? = exercise.category == .strength ? 135.0 : nil
            let position = Double(index + 1)
            
            return createExerciseTemplate(
                exercise: exercise,
                setCount: setCount,
                reps: reps,
                weight: weight,
                position: position,
                dayTemplate: dayTemplate
            )
        }
    }
    
    // MARK: - DayTemplate Factory
    
    /// Create a realistic day template
    public static func createDayTemplate(
        weekday: Weekday,
        notes: String? = nil,
        workoutTemplate: WorkoutTemplate? = nil,
        isRestDay: Bool = false
    ) -> DayTemplate {
        let dayTemplate = DayTemplate(
            weekday: weekday,
            notes: notes ?? "\(weekday.fullName) workout"
        )
        dayTemplate.workoutTemplate = workoutTemplate
        return dayTemplate
    }
    
    /// Create day templates for a workout template
    public static func createDayTemplatesForWorkout(
        workoutTemplate: WorkoutTemplate,
        weekdays: [Weekday] = [.monday, .wednesday, .friday]
    ) -> [DayTemplate] {
        return weekdays.map { weekday in
            createDayTemplate(
                weekday: weekday,
                workoutTemplate: workoutTemplate
            )
        }
    }
    
    // MARK: - WorkoutPlan Factory
    
    /// Create a realistic workout plan
    public static func createWorkoutPlan(
        customName: String,
        template: WorkoutTemplate,
        startDate: Date = Date(),
        endDate: Date? = nil,
        isActive: Bool = true
    ) -> WorkoutPlan {
        let plan = WorkoutPlan(customName: customName, template: template)
        
        // Note: StartDate, endDate, and isActive properties would need to be added to WorkoutPlan model
        // For now, we'll just create the basic plan
        
        return plan
    }
    
    /// Create common workout plans
    public static func createCommonWorkoutPlans(templates: [WorkoutTemplate]) -> [WorkoutPlan] {
        return templates.enumerated().map { index, template in
            createWorkoutPlan(
                customName: "Plan \(index + 1) - \(template.name)",
                template: template
            )
        }
    }
    
    // MARK: - PerformedExercise Factory
    
    /// Create a realistic performed exercise
    public static func createPerformedExercise(
        exercise: Exercise,
        reps: Int = 10,
        weight: Double = 0,
        performedAt: Date = Date(),
        workoutSession: WorkoutSession? = nil
    ) -> PerformedExercise {
        let performedExercise = PerformedExercise(
            performedAt: performedAt,
            reps: reps,
            weight: weight,
            exercise: exercise,
            workoutSession: workoutSession
        )
        
        return performedExercise
    }
    
    /// Create performed exercises for a date range
    public static func createPerformedExercisesForDateRange(
        from startDate: Date,
        to endDate: Date,
        exercises: [Exercise]
    ) -> [PerformedExercise] {
        var performedExercises: [PerformedExercise] = []
        let calendar = Calendar.current
        var currentDate = startDate
        
        while currentDate <= endDate {
            // Randomly select exercises for each day
            let randomExercises = Array(exercises.shuffled().prefix(Int.random(in: 1...3)))
            
            for exercise in randomExercises {
                let performedExercise = createPerformedExercise(
                    exercise: exercise,
                    reps: Int.random(in: 8...15),
                    weight: Double.random(in: 0...200),
                    performedAt: currentDate
                )
                performedExercises.append(performedExercise)
            }
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return performedExercises
    }
    
    // MARK: - Complete Workout Setup Factory
    
    /// Create a complete workout setup with all related entities
    public static func createCompleteWorkoutSetup(
        persistenceController: InMemoryPersistenceController
    ) -> (Exercise, WorkoutTemplate, DayTemplate, ExerciseTemplate, WorkoutPlan, WorkoutSession, SessionExercise, CompletedSet) {
        
        // Create exercise
        let exercise = createExercise(
            name: "Bench Press",
            category: .strength,
            instructions: "Lie on bench, lower bar to chest, press up"
        )
        persistenceController.create(exercise)
        
        // Create workout template
        let template = createWorkoutTemplate(
            name: "Upper Body Strength",
            summary: "Focus on chest, shoulders, and triceps"
        )
        persistenceController.create(template)
        
        // Create day template
        let dayTemplate = createDayTemplate(
            weekday: .monday,
            notes: "Chest and triceps day",
            workoutTemplate: template
        )
        persistenceController.create(dayTemplate)
        
        // Create exercise template
        let exerciseTemplate = createExerciseTemplate(
            exercise: exercise,
            setCount: 4,
            reps: 8,
            weight: 185,
            position: 1.0,
            dayTemplate: dayTemplate
        )
        persistenceController.create(exerciseTemplate)
        
        // Create workout plan
        let plan = createWorkoutPlan(
            customName: "My Strength Journey",
            template: template
        )
        persistenceController.create(plan)
        
        // Create workout session
        let session = createWorkoutSession(
            title: "Monday Morning Workout",
            plan: plan
        )
        persistenceController.create(session)
        
        // Create session exercise
        let sessionExercise = createSessionExercise(
            exercise: exercise,
            plannedSets: 4,
            plannedReps: 8,
            plannedWeight: 185,
            position: 1.0,
            session: session
        )
        persistenceController.create(sessionExercise)
        
        // Create completed set
        let completedSet = createCompletedSet(
            reps: 8,
            weight: 185,
            sessionExercise: sessionExercise
        )
        persistenceController.create(completedSet)
        
        return (exercise, template, dayTemplate, exerciseTemplate, plan, session, sessionExercise, completedSet)
    }
} 