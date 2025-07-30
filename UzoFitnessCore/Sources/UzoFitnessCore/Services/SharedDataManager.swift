import Foundation

/// Concrete implementation of SharedDataManager using App Groups UserDefaults
@MainActor
public class SharedDataManager: SharedDataManagerProtocol {
    
    // MARK: - Constants
    
    private static let appGroupIdentifier = "group.com.kosiuzodinma.UzoFitness"
    
    private enum Keys {
        static let workoutState = "current_workout_state"
        static let currentExercise = "current_exercise_data"
        static let restTimerState = "rest_timer_state"
        static let setCompletions = "set_completions"
    }
    
    // MARK: - Properties
    
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // MARK: - Initialization
    
    public init() throws {
        guard let sharedDefaults = UserDefaults(suiteName: Self.appGroupIdentifier) else {
            AppLogger.error("❌ [SharedDataManager.init] Failed to create UserDefaults with suite: \(Self.appGroupIdentifier)", category: "SharedDataManager")
            throw SharedDataError.appGroupsNotAvailable
        }
        self.userDefaults = sharedDefaults
        
        // Configure JSON encoder/decoder
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        
        AppLogger.debug("🔄 [SharedDataManager.init] Initialized with App Group: \(Self.appGroupIdentifier)", category: "SharedDataManager")
        
        // Test App Groups access by writing and reading a test value
        testAppGroupsAccess()
    }
    
    private func testAppGroupsAccess() {
        let testKey = "app_groups_test"
        let testValue = "test_\(Date().timeIntervalSince1970)"
        
        AppLogger.debug("🔄 [SharedDataManager.testAppGroupsAccess] Testing App Groups access", category: "SharedDataManager")
        
        // Write test value
        userDefaults.set(testValue, forKey: testKey)
        userDefaults.synchronize()
        
        // Read test value
        let readValue = userDefaults.string(forKey: testKey)
        
        if readValue == testValue {
            AppLogger.info("✅ [SharedDataManager.testAppGroupsAccess] App Groups working correctly", category: "SharedDataManager")
        } else {
            AppLogger.error("❌ [SharedDataManager.testAppGroupsAccess] App Groups test failed - wrote: \(testValue), read: \(readValue ?? "nil")", category: "SharedDataManager")
        }
        
        // Clean up test value
        userDefaults.removeObject(forKey: testKey)
    }
    

    
    // MARK: - Workout State Management
    
    public func getCurrentWorkoutState() async -> WorkoutState? {
        AppLogger.debug("🔄 [SharedDataManager.getCurrentWorkoutState] Reading workout state", category: "SharedDataManager")
        
        guard let data = userDefaults.data(forKey: Keys.workoutState) else {
            AppLogger.info("📊 [SharedDataManager] No workout state found", category: "SharedDataManager")
            return nil
        }
        
        do {
            let state = try decoder.decode(WorkoutState.self, from: data)
            AppLogger.debug("✅ [SharedDataManager.getCurrentWorkoutState] Successfully read workout state: \(state.workoutName)", category: "SharedDataManager")
            return state
        } catch {
            AppLogger.error("❌ [SharedDataManager.getCurrentWorkoutState] Failed to decode workout state: \(error.localizedDescription)", category: "SharedDataManager", error: error)
            return nil
        }
    }
    
    public func saveCurrentWorkoutState(_ state: WorkoutState) async throws {
        AppLogger.debug("🔄 [SharedDataManager.saveCurrentWorkoutState] Saving workout state: \(state.workoutName)", category: "SharedDataManager")
        
        do {
            let data = try encoder.encode(state)
            userDefaults.set(data, forKey: Keys.workoutState)
            let success = userDefaults.synchronize()
            AppLogger.debug("✅ [SharedDataManager.saveCurrentWorkoutState] Successfully saved workout state, sync: \(success), data size: \(data.count) bytes", category: "SharedDataManager")
        } catch {
            AppLogger.error("❌ [SharedDataManager.saveCurrentWorkoutState] Failed to encode workout state: \(error.localizedDescription)", category: "SharedDataManager", error: error)
            throw SharedDataError.encodingFailed
        }
    }
    
    public func clearCurrentWorkoutState() async throws {
        AppLogger.debug("🔄 [SharedDataManager.clearCurrentWorkoutState] Clearing workout state", category: "SharedDataManager")
        userDefaults.removeObject(forKey: Keys.workoutState)
        AppLogger.debug("✅ [SharedDataManager.clearCurrentWorkoutState] Successfully cleared workout state", category: "SharedDataManager")
    }
    
    // MARK: - Current Exercise Management
    
    public func getCurrentExercise() async -> CurrentExerciseData? {
        AppLogger.debug("🔄 [SharedDataManager.getCurrentExercise] Reading current exercise", category: "SharedDataManager")
        
        guard let data = userDefaults.data(forKey: Keys.currentExercise) else {
            AppLogger.info("📊 [SharedDataManager] No current exercise found", category: "SharedDataManager")
            return nil
        }
        
        do {
            let exercise = try decoder.decode(CurrentExerciseData.self, from: data)
            AppLogger.debug("✅ [SharedDataManager.getCurrentExercise] Successfully read exercise: \(exercise.exerciseName)", category: "SharedDataManager")
            return exercise
        } catch {
            AppLogger.error("❌ [SharedDataManager.getCurrentExercise] Failed to decode exercise: \(error.localizedDescription)", category: "SharedDataManager", error: error)
            return nil
        }
    }
    
    public func saveCurrentExercise(_ exercise: CurrentExerciseData) async throws {
        AppLogger.debug("🔄 [SharedDataManager.saveCurrentExercise] Saving exercise: \(exercise.exerciseName)", category: "SharedDataManager")
        
        do {
            let data = try encoder.encode(exercise)
            userDefaults.set(data, forKey: Keys.currentExercise)
            let success = userDefaults.synchronize()
            AppLogger.debug("✅ [SharedDataManager.saveCurrentExercise] Successfully saved exercise, sync: \(success), data size: \(data.count) bytes", category: "SharedDataManager")
        } catch {
            AppLogger.error("❌ [SharedDataManager.saveCurrentExercise] Failed to encode exercise: \(error.localizedDescription)", category: "SharedDataManager", error: error)
            throw SharedDataError.encodingFailed
        }
    }
    
    // MARK: - Set Completion Management
    
    public func markSetCompleted(exerciseId: UUID, setIndex: Int) async throws {
        AppLogger.debug("🔄 [SharedDataManager.markSetCompleted] Marking set \(setIndex) completed for exercise: \(exerciseId)", category: "SharedDataManager")
        
        // Get current exercise data
        guard var currentExercise = await getCurrentExercise(),
              currentExercise.exerciseId == exerciseId else {
            AppLogger.error("❌ [SharedDataManager.markSetCompleted] No matching current exercise found", category: "SharedDataManager")
            throw SharedDataError.dataCorrupted
        }
        
        // Update completed sets count
        let newCompletedSets = min(currentExercise.completedSets + 1, currentExercise.totalSets)
        let newCurrentSetIndex = min(currentExercise.currentSetIndex + 1, currentExercise.totalSets - 1)
        
        // Create updated exercise data
        let updatedExercise = CurrentExerciseData(
            exerciseId: currentExercise.exerciseId,
            exerciseName: currentExercise.exerciseName,
            totalSets: currentExercise.totalSets,
            completedSets: newCompletedSets,
            currentSetIndex: newCurrentSetIndex,
            plannedReps: currentExercise.plannedReps,
            plannedWeight: currentExercise.plannedWeight,
            instructions: currentExercise.instructions,
            isSuperset: currentExercise.isSuperset,
            supersetPosition: currentExercise.supersetPosition,
            supersetTotal: currentExercise.supersetTotal
        )
        
        // Save updated exercise data
        try await saveCurrentExercise(updatedExercise)
        
        AppLogger.debug("✅ [SharedDataManager.markSetCompleted] Successfully marked set completed", category: "SharedDataManager")
    }
    
    // MARK: - Rest Timer Management
    
    public func getRestTimerState() async -> RestTimerState? {
        AppLogger.debug("🔄 [SharedDataManager.getRestTimerState] Reading rest timer state", category: "SharedDataManager")
        
        guard let data = userDefaults.data(forKey: Keys.restTimerState) else {
            AppLogger.info("📊 [SharedDataManager] No rest timer state found", category: "SharedDataManager")
            return nil
        }
        
        do {
            let state = try decoder.decode(RestTimerState.self, from: data)
            AppLogger.debug("✅ [SharedDataManager.getRestTimerState] Successfully read timer state", category: "SharedDataManager")
            return state
        } catch {
            AppLogger.error("❌ [SharedDataManager.getRestTimerState] Failed to decode timer state: \(error.localizedDescription)", category: "SharedDataManager", error: error)
            return nil
        }
    }
    
    public func saveRestTimerState(_ state: RestTimerState) async throws {
        AppLogger.debug("🔄 [SharedDataManager.saveRestTimerState] Saving timer state: active=\(state.isActive), duration=\(state.duration)", category: "SharedDataManager")
        
        do {
            let data = try encoder.encode(state)
            userDefaults.set(data, forKey: Keys.restTimerState)
            AppLogger.debug("✅ [SharedDataManager.saveRestTimerState] Successfully saved timer state", category: "SharedDataManager")
        } catch {
            AppLogger.error("❌ [SharedDataManager.saveRestTimerState] Failed to encode timer state: \(error.localizedDescription)", category: "SharedDataManager", error: error)
            throw SharedDataError.encodingFailed
        }
    }
    
    public func clearRestTimerState() async throws {
        AppLogger.debug("🔄 [SharedDataManager.clearRestTimerState] Clearing timer state", category: "SharedDataManager")
        userDefaults.removeObject(forKey: Keys.restTimerState)
        AppLogger.debug("✅ [SharedDataManager.clearRestTimerState] Successfully cleared timer state", category: "SharedDataManager")
    }
}

// MARK: - Mock Implementation

/// Mock implementation of SharedDataManager for testing and previews
@MainActor
public class MockSharedDataManager: SharedDataManagerProtocol {
    
    // MARK: - Mock Properties
    
    public var mockWorkoutState: WorkoutState?
    public var mockCurrentExercise: CurrentExerciseData?
    public var mockRestTimerState: RestTimerState?
    public var shouldThrowError = false
    
    public init() {
        AppLogger.debug("🔄 [MockSharedDataManager.init] Initialized mock shared data manager", category: "MockSharedDataManager")
    }
    
    public func getCurrentWorkoutState() async -> WorkoutState? {
        AppLogger.debug("🔄 [MockSharedDataManager.getCurrentWorkoutState] Returning mock workout state", category: "MockSharedDataManager")
        return mockWorkoutState
    }
    
    public func saveCurrentWorkoutState(_ state: WorkoutState) async throws {
        AppLogger.debug("🔄 [MockSharedDataManager.saveCurrentWorkoutState] Saving mock workout state", category: "MockSharedDataManager")
        if shouldThrowError {
            throw SharedDataError.encodingFailed
        }
        mockWorkoutState = state
    }
    
    public func clearCurrentWorkoutState() async throws {
        AppLogger.debug("🔄 [MockSharedDataManager.clearCurrentWorkoutState] Clearing mock workout state", category: "MockSharedDataManager")
        if shouldThrowError {
            throw SharedDataError.dataCorrupted
        }
        mockWorkoutState = nil
    }
    
    public func getCurrentExercise() async -> CurrentExerciseData? {
        AppLogger.debug("🔄 [MockSharedDataManager.getCurrentExercise] Returning mock current exercise", category: "MockSharedDataManager")
        return mockCurrentExercise
    }
    
    public func saveCurrentExercise(_ exercise: CurrentExerciseData) async throws {
        AppLogger.debug("🔄 [MockSharedDataManager.saveCurrentExercise] Saving mock exercise", category: "MockSharedDataManager")
        if shouldThrowError {
            throw SharedDataError.encodingFailed
        }
        mockCurrentExercise = exercise
    }
    
    public func markSetCompleted(exerciseId: UUID, setIndex: Int) async throws {
        AppLogger.debug("🔄 [MockSharedDataManager.markSetCompleted] Marking mock set completed", category: "MockSharedDataManager")
        if shouldThrowError {
            throw SharedDataError.dataCorrupted
        }
        
        // Update mock current exercise if it exists and matches
        if var exercise = mockCurrentExercise, exercise.exerciseId == exerciseId {
            let newCompletedSets = min(exercise.completedSets + 1, exercise.totalSets)
            let newCurrentSetIndex = min(exercise.currentSetIndex + 1, exercise.totalSets - 1)
            
            mockCurrentExercise = CurrentExerciseData(
                exerciseId: exercise.exerciseId,
                exerciseName: exercise.exerciseName,
                totalSets: exercise.totalSets,
                completedSets: newCompletedSets,
                currentSetIndex: newCurrentSetIndex,
                plannedReps: exercise.plannedReps,
                plannedWeight: exercise.plannedWeight,
                instructions: exercise.instructions,
                isSuperset: exercise.isSuperset,
                supersetPosition: exercise.supersetPosition,
                supersetTotal: exercise.supersetTotal
            )
        }
    }
    
    public func getRestTimerState() async -> RestTimerState? {
        AppLogger.debug("🔄 [MockSharedDataManager.getRestTimerState] Returning mock timer state", category: "MockSharedDataManager")
        return mockRestTimerState
    }
    
    public func saveRestTimerState(_ state: RestTimerState) async throws {
        AppLogger.debug("🔄 [MockSharedDataManager.saveRestTimerState] Saving mock timer state", category: "MockSharedDataManager")
        if shouldThrowError {
            throw SharedDataError.encodingFailed
        }
        mockRestTimerState = state
    }
    
    public func clearRestTimerState() async throws {
        AppLogger.debug("🔄 [MockSharedDataManager.clearRestTimerState] Clearing mock timer state", category: "MockSharedDataManager")
        if shouldThrowError {
            throw SharedDataError.dataCorrupted
        }
        mockRestTimerState = nil
    }
    
} 