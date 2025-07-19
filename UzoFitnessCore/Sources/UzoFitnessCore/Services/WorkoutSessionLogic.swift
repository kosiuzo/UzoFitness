import Foundation

// MARK: - Workout Session Logic
public struct WorkoutSessionLogic {
    
    // MARK: - Session State Management
    
    /// Determines if a session can be finished (all exercises completed)
    public static func canFinishSession(_ session: WorkoutSession) -> Bool {
        guard !session.sessionExercises.isEmpty else { return false }
        return session.sessionExercises.allSatisfy { $0.isCompleted }
    }
    
    /// Calculates total volume for a workout session
    public static func calculateTotalVolume(_ session: WorkoutSession) -> Double {
        session.sessionExercises.reduce(0) { total, sessionExercise in
            total + sessionExercise.completedSets.reduce(0) { setTotal, set in
                setTotal + (Double(set.reps) * set.weight)
            }
        }
    }
    
    /// Calculates total duration for a workout session
    public static func calculateDuration(_ session: WorkoutSession) -> TimeInterval? {
        return session.duration
    }
    
    /// Gets the current exercise index in a session
    public static func getCurrentExerciseIndex(_ session: WorkoutSession) -> Int {
        return session.sessionExercises.firstIndex { !$0.isCompleted } ?? 0
    }
    
    /// Gets the current exercise in a session
    public static func getCurrentExercise(_ session: WorkoutSession) -> SessionExercise? {
        let currentIndex = getCurrentExerciseIndex(session)
        guard currentIndex < session.sessionExercises.count else { return nil }
        return session.sessionExercises[currentIndex]
    }
    
    /// Checks if a session has an incomplete session for today
    public static func hasIncompleteSession(for date: Date, in sessions: [WorkoutSession]) -> Bool {
        let calendar = Calendar.current
        return sessions.contains { session in
            calendar.isDate(session.date, inSameDayAs: date) && !session.sessionExercises.allSatisfy { $0.isCompleted }
        }
    }
    
    // MARK: - Exercise Grouping Logic
    
    /// Groups exercises by superset for display
    public static func groupExercisesBySuperset(_ exercises: [SessionExercise]) -> [(Int?, [SessionExercise])] {
        let sortedExercises = exercises.sorted { $0.position < $1.position }
        var result: [(Int?, [SessionExercise])] = []
        var currentSupersetID: UUID? = nil
        var currentGroup: [SessionExercise] = []
        
        for exercise in sortedExercises {
            if let supersetID = exercise.supersetID {
                if supersetID != currentSupersetID {
                    // Finish previous group if any
                    if !currentGroup.isEmpty {
                        result.append((currentSupersetID != nil ? getSupersetNumber(for: currentSupersetID!, in: exercises) : nil, currentGroup))
                        currentGroup = []
                    }
                    currentSupersetID = supersetID
                }
                currentGroup.append(exercise)
            } else {
                // Finish previous group if any
                if !currentGroup.isEmpty {
                    result.append((currentSupersetID != nil ? getSupersetNumber(for: currentSupersetID!, in: exercises) : nil, currentGroup))
                    currentGroup = []
                    currentSupersetID = nil
                }
                // Add non-superset exercise as its own group
                result.append((nil, [exercise]))
            }
        }
        // Add last group if any
        if !currentGroup.isEmpty {
            result.append((currentSupersetID != nil ? getSupersetNumber(for: currentSupersetID!, in: exercises) : nil, currentGroup))
        }
        return result
    }
    
    /// Gets the superset number for a given superset ID
    private static func getSupersetNumber(for supersetID: UUID, in exercises: [SessionExercise]) -> Int {
        let supersetIDs = Set(exercises.compactMap { $0.supersetID }).sorted()
        return supersetIDs.firstIndex(of: supersetID) ?? 0
    }
    
    // MARK: - Session Exercise UI Conversion
    
    /// Converts a SessionExercise to SessionExerciseUI for display
    public static func convertToSessionExerciseUI(_ sessionExercise: SessionExercise) -> SessionExerciseUI {
        let isSupersetHead = sessionExercise.supersetID != nil && 
            sessionExercise.session?.sessionExercises
                .filter { $0.supersetID == sessionExercise.supersetID }
                .min(by: { $0.position < $1.position })?.id == sessionExercise.id
        
        return SessionExerciseUI(
            id: sessionExercise.id,
            name: sessionExercise.exercise.name,
            sets: sessionExercise.completedSets.sorted(by: { $0.position < $1.position }),
            plannedSets: sessionExercise.plannedSets,
            plannedReps: sessionExercise.plannedReps,
            plannedWeight: sessionExercise.plannedWeight,
            currentSet: sessionExercise.currentSet,
            timerRemaining: sessionExercise.restTimer,
            isSupersetHead: isSupersetHead,
            isCompleted: sessionExercise.isCompleted,
            position: sessionExercise.position,
            supersetID: sessionExercise.supersetID
        )
    }
}

// MARK: - SessionExerciseUI Helper Struct
public struct SessionExerciseUI: Identifiable, Hashable {
    public let id: UUID
    public let name: String
    public let sets: [CompletedSet]
    public let plannedSets: Int
    public let plannedReps: Int
    public let plannedWeight: Double?
    public let currentSet: Int
    public let timerRemaining: TimeInterval?
    public let isSupersetHead: Bool
    public let isCompleted: Bool
    public let position: Double
    public let supersetID: UUID?
    
    public init(
        id: UUID,
        name: String,
        sets: [CompletedSet],
        plannedSets: Int,
        plannedReps: Int,
        plannedWeight: Double?,
        currentSet: Int,
        timerRemaining: TimeInterval?,
        isSupersetHead: Bool,
        isCompleted: Bool,
        position: Double,
        supersetID: UUID?
    ) {
        self.id = id
        self.name = name
        self.sets = sets
        self.plannedSets = plannedSets
        self.plannedReps = plannedReps
        self.plannedWeight = plannedWeight
        self.currentSet = currentSet
        self.timerRemaining = timerRemaining
        self.isSupersetHead = isSupersetHead
        self.isCompleted = isCompleted
        self.position = position
        self.supersetID = supersetID
    }
} 