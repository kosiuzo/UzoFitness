import Foundation

/// Protocol for managing shared data between iOS and watchOS apps via App Groups
public protocol SharedDataManagerProtocol {
    /// Read current workout state from shared storage
    func getCurrentWorkoutState() async -> WorkoutState?
    
    /// Write current workout state to shared storage
    func saveCurrentWorkoutState(_ state: WorkoutState) async throws
    
    /// Clear current workout state from shared storage
    func clearCurrentWorkoutState() async throws
    
    /// Read current exercise data from shared storage
    func getCurrentExercise() async -> CurrentExerciseData?
    
    /// Write current exercise data to shared storage
    func saveCurrentExercise(_ exercise: CurrentExerciseData) async throws
    
    /// Mark a set as completed in shared storage
    func markSetCompleted(exerciseId: UUID, setIndex: Int) async throws
    
    /// Get rest timer state from shared storage
    func getRestTimerState() async -> RestTimerState?
    
    /// Save rest timer state to shared storage
    func saveRestTimerState(_ state: RestTimerState) async throws
    
    /// Clear rest timer state from shared storage
    func clearRestTimerState() async throws
}

// MARK: - Data Structures

/// Represents the current workout state
public struct WorkoutState: Codable, Sendable {
    let sessionId: UUID
    let workoutName: String
    let isActive: Bool
    let startTime: Date
    let currentExerciseIndex: Int
    let totalExercises: Int
    
    public init(sessionId: UUID, workoutName: String, isActive: Bool, startTime: Date, currentExerciseIndex: Int, totalExercises: Int) {
        self.sessionId = sessionId
        self.workoutName = workoutName
        self.isActive = isActive
        self.startTime = startTime
        self.currentExerciseIndex = currentExerciseIndex
        self.totalExercises = totalExercises
    }
}

/// Represents current exercise data for the watch
public struct CurrentExerciseData: Codable, Sendable {
    public let exerciseId: UUID
    public let exerciseName: String
    public let totalSets: Int
    public let completedSets: Int
    public let currentSetIndex: Int
    public let plannedReps: Int?
    public let plannedWeight: Double?
    public let instructions: String?
    public let isSuperset: Bool
    public let supersetPosition: Int?
    public let supersetTotal: Int?
    
    public init(exerciseId: UUID, exerciseName: String, totalSets: Int, completedSets: Int, currentSetIndex: Int, plannedReps: Int? = nil, plannedWeight: Double? = nil, instructions: String? = nil, isSuperset: Bool = false, supersetPosition: Int? = nil, supersetTotal: Int? = nil) {
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.totalSets = totalSets
        self.completedSets = completedSets
        self.currentSetIndex = currentSetIndex
        self.plannedReps = plannedReps
        self.plannedWeight = plannedWeight
        self.instructions = instructions
        self.isSuperset = isSuperset
        self.supersetPosition = supersetPosition
        self.supersetTotal = supersetTotal
    }
}

/// Represents rest timer state
public struct RestTimerState: Codable, Sendable {
    public let isActive: Bool
    public let duration: TimeInterval
    public let remainingTime: TimeInterval
    public let startTime: Date?
    public let exerciseName: String?
    
    public init(isActive: Bool, duration: TimeInterval, remainingTime: TimeInterval, startTime: Date? = nil, exerciseName: String? = nil) {
        self.isActive = isActive
        self.duration = duration
        self.remainingTime = remainingTime
        self.startTime = startTime
        self.exerciseName = exerciseName
    }
}

/// Custom errors for SharedDataManager
public enum SharedDataError: LocalizedError {
    case appGroupsNotAvailable
    case dataCorrupted
    case encodingFailed
    case decodingFailed
    case writePermissionDenied
    
    public var errorDescription: String? {
        switch self {
        case .appGroupsNotAvailable:
            return "App Groups capability is not available"
        case .dataCorrupted:
            return "Shared data is corrupted"
        case .encodingFailed:
            return "Failed to encode data for sharing"
        case .decodingFailed:
            return "Failed to decode shared data"
        case .writePermissionDenied:
            return "Permission denied to write shared data"
        }
    }
} 