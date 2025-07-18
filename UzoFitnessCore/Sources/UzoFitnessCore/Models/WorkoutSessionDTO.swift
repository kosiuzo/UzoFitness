import Foundation

// MARK: - Data Transfer Objects for Watch Connectivity

/// Lightweight representation of workout session data for watch sync
public struct WorkoutSessionDTO: Codable, Identifiable {
    public let id: UUID
    public let date: Date
    public let title: String
    public let duration: TimeInterval?
    public let exercises: [SessionExerciseDTO]
    
    public init(
        id: UUID,
        date: Date,
        title: String,
        duration: TimeInterval? = nil,
        exercises: [SessionExerciseDTO] = []
    ) {
        self.id = id
        self.date = date
        self.title = title
        self.duration = duration
        self.exercises = exercises
    }
}

/// Lightweight representation of session exercise data for watch sync
public struct SessionExerciseDTO: Codable, Identifiable {
    public let id: UUID
    public let exerciseName: String
    public let plannedSets: Int
    public let plannedReps: Int
    public let plannedWeight: Double?
    public let position: Double
    public let supersetID: UUID?
    public let currentSet: Int
    public let isCompleted: Bool
    public let restTimer: TimeInterval?
    public let completedSets: [CompletedSetDTO]
    
    public init(
        id: UUID,
        exerciseName: String,
        plannedSets: Int,
        plannedReps: Int,
        plannedWeight: Double? = nil,
        position: Double,
        supersetID: UUID? = nil,
        currentSet: Int = 0,
        isCompleted: Bool = false,
        restTimer: TimeInterval? = nil,
        completedSets: [CompletedSetDTO] = []
    ) {
        self.id = id
        self.exerciseName = exerciseName
        self.plannedSets = plannedSets
        self.plannedReps = plannedReps
        self.plannedWeight = plannedWeight
        self.position = position
        self.supersetID = supersetID
        self.currentSet = currentSet
        self.isCompleted = isCompleted
        self.restTimer = restTimer
        self.completedSets = completedSets
    }
}

/// Lightweight representation of completed set data for watch sync
public struct CompletedSetDTO: Codable, Identifiable {
    public let id: UUID
    public let reps: Int
    public let weight: Double
    public let isCompleted: Bool
    public let position: Int
    
    public init(
        id: UUID,
        reps: Int,
        weight: Double,
        isCompleted: Bool = true,
        position: Int = 0
    ) {
        self.id = id
        self.reps = reps
        self.weight = weight
        self.isCompleted = isCompleted
        self.position = position
    }
}

// MARK: - Watch Connectivity Message Types

/// Messages sent between iOS and watchOS apps
public enum WatchMessage: Codable {
    case sessionStarted(WorkoutSessionDTO)
    case sessionUpdated(WorkoutSessionDTO)
    case sessionCompleted(UUID)
    case setCompleted(exerciseID: UUID, setData: CompletedSetDTO)
    case restTimerStarted(exerciseID: UUID, duration: TimeInterval)
    case restTimerStopped(exerciseID: UUID)
    case exerciseCompleted(exerciseID: UUID)
    case startWorkoutForToday
    case syncRequest
    case syncResponse(WorkoutSessionDTO?)
    case error(String)
}

/// Current workout state for watch sync
public struct WorkoutState: Codable {
    public let hasActiveSession: Bool
    public let currentSession: WorkoutSessionDTO?
    public let currentExercise: SessionExerciseDTO?
    public let currentSuperset: [SessionExerciseDTO]?
    
    public init(
        hasActiveSession: Bool,
        currentSession: WorkoutSessionDTO? = nil,
        currentExercise: SessionExerciseDTO? = nil,
        currentSuperset: [SessionExerciseDTO]? = nil
    ) {
        self.hasActiveSession = hasActiveSession
        self.currentSession = currentSession
        self.currentExercise = currentExercise
        self.currentSuperset = currentSuperset
    }
}