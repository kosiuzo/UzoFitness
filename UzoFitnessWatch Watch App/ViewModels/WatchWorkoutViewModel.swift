import Foundation
import SwiftData
import Combine
import WatchKit
import UzoFitnessCore

// MARK: - Watch Workout Intent Actions
enum WatchWorkoutIntent {
    case startTodaysWorkout
    case completeSet(exerciseID: UUID, setIndex: Int, reps: Int, weight: Double)
    case startRestTimer(duration: TimeInterval, exerciseName: String?)
    case stopRestTimer
    case nextExercise
    case previousExercise
    case completeWorkout
    case cancelWorkout
}

// MARK: - Watch Workout State
enum WatchWorkoutState {
    case idle
    case loading
    case noWorkoutToday
    case workoutAvailable(WorkoutPlan)
    case workoutInProgress(SharedWorkoutSession)
    case workoutCompleted
    case error(String)
}

// MARK: - Watch Workout ViewModel
@MainActor
public final class WatchWorkoutViewModel: ObservableObject {
    
    // MARK: - Published State
    @Published var state: WatchWorkoutState = .idle
    @Published var currentExercise: SharedSessionExercise?
    @Published var currentExerciseIndex: Int = 0
    @Published var totalExercises: Int?
    @Published var allExercises: [SharedSessionExercise] = []
    @Published var workoutProgress: SharedWorkoutProgress?
    @Published var isRestTimerRunning: Bool = false
    @Published var restTimeRemaining: TimeInterval = 0
    @Published var connectionStatus: SyncState = .idle
    
    // MARK: - Dependencies
    private let modelContext: ModelContext
    private let syncCoordinator: SyncCoordinatorProtocol
    private let sharedData: SharedDataProtocol
    private let calendar: CalendarProtocol
    
    // MARK: - Private State
    private var cancellables = Set<AnyCancellable>()
    private var restTimer: Timer?
    private var currentSession: SharedWorkoutSession?
    
    // MARK: - Initialization
    public init(
        modelContext: ModelContext,
        syncCoordinator: SyncCoordinatorProtocol,
        sharedData: SharedDataProtocol = SharedDataManager.shared,
        calendar: CalendarProtocol = CalendarService()
    ) {
        self.modelContext = modelContext
        self.syncCoordinator = syncCoordinator
        self.sharedData = sharedData
        self.calendar = calendar
        
        setupObservers()
        loadInitialState()
    }
    
    // MARK: - Setup
    private func setupObservers() {
        // Observe sync coordinator state
        if let syncCoordinator = syncCoordinator as? SyncCoordinator {
            syncCoordinator.$state
                .receive(on: DispatchQueue.main)
                .assign(to: \.connectionStatus, on: self)
                .store(in: &cancellables)
        }
        
        // Add sync event handler
        syncCoordinator.addSyncEventHandler { [weak self] event in
            self?.handleSyncEvent(event)
        }
    }
    
    private func loadInitialState() {
        // Check if there's an ongoing workout session
        if let session = sharedData.getCurrentWorkoutSession() {
            currentSession = session
            currentExerciseIndex = session.currentExerciseIndex
            totalExercises = session.totalExercises
            state = .workoutInProgress(session)
            loadCurrentExercise()
            return
        }
        
        // Check if today has a workout
        checkTodaysWorkout()
    }
    
    // MARK: - Intent Handling
    func handle(_ intent: WatchWorkoutIntent) {
        switch intent {
        case .startTodaysWorkout:
            startTodaysWorkout()
            
        case .completeSet(let exerciseID, let setIndex, let reps, let weight):
            completeSet(exerciseID: exerciseID, setIndex: setIndex, reps: reps, weight: weight)
            
        case .startRestTimer(let duration, let exerciseName):
            startRestTimer(duration: duration, exerciseName: exerciseName)
            
        case .stopRestTimer:
            stopRestTimer()
            
        case .nextExercise:
            advanceToNextExercise()
            
        case .previousExercise:
            goToPreviousExercise()
            
        case .completeWorkout:
            completeWorkout()
            
        case .cancelWorkout:
            cancelWorkout()
        }
    }
    
    // MARK: - Workout Management
    private func checkTodaysWorkout() {
        state = .loading
        
        Task {
            do {
                let today = (calendar as? CalendarService)?.getCurrentWeekday() ?? .monday
                let plans = try await fetchWorkoutPlans()
                
                var todaysPlan: WorkoutPlan?
                for plan in plans {
                    if plan.template?.dayTemplates.contains(where: { $0.weekday == today }) ?? false {
                        todaysPlan = plan
                        break
                    }
                }
                
                if let todaysPlan = todaysPlan {
                    state = .workoutAvailable(todaysPlan)
                } else {
                    state = .noWorkoutToday
                }
            } catch {
                state = .error("Failed to load workout: \(error.localizedDescription)")
            }
        }
    }
    
    private func startTodaysWorkout() {
        guard case .workoutAvailable(let plan) = state else { return }
        
        state = .loading
        
        Task {
            do {
                let session = try await createWorkoutSession(from: plan)
                currentSession = session
                
                // Store in shared data and sync
                try sharedData.storeCurrentWorkoutSession(session)
                syncCoordinator.syncWorkoutSession(session)
                
                state = .workoutInProgress(session)
                loadCurrentExercise()
                
                // Haptic feedback
                WKInterfaceDevice.current().play(.start)
                
            } catch {
                state = .error("Failed to start workout: \(error.localizedDescription)")
            }
        }
    }
    
    private func completeSet(exerciseID: UUID, setIndex: Int, reps: Int, weight: Double) {
        guard let session = currentSession,
              let exerciseIndex = session.exercises.firstIndex(where: { $0.exerciseId == exerciseID }) else { return }
        
        var updatedExercise = session.exercises[exerciseIndex]
        
        // Add completed set to the exercise
        let completedSet = SharedCompletedSet(reps: reps, weight: weight)
        var updatedCompletedSets = updatedExercise.completedSets
        updatedCompletedSets.append(completedSet)
        
        // Update exercise with new completed set and increment current set
        let newCurrentSet = min(updatedExercise.currentSet + 1, updatedExercise.plannedSets)
        let isCompleted = newCurrentSet >= updatedExercise.plannedSets
        
        updatedExercise = SharedSessionExercise(
            id: updatedExercise.id,
            exerciseId: updatedExercise.exerciseId,
            name: updatedExercise.name,
            category: updatedExercise.category,
            plannedSets: updatedExercise.plannedSets,
            plannedReps: updatedExercise.plannedReps,
            plannedWeight: updatedExercise.plannedWeight,
            position: updatedExercise.position,
            currentSet: newCurrentSet,
            isCompleted: isCompleted,
            completedSets: updatedCompletedSets
        )
        
        // Update the exercises array in the session
        var updatedExercises = session.exercises
        updatedExercises[exerciseIndex] = updatedExercise
        
        let updatedSession = SharedWorkoutSession(
            id: session.id,
            title: session.title,
            startTime: session.startTime,
            duration: session.duration,
            currentExerciseIndex: session.currentExerciseIndex,
            totalExercises: session.totalExercises,
            exercises: updatedExercises
        )
        
        // Update local state
        currentSession = updatedSession
        allExercises = updatedExercises
        currentExercise = updatedExercise
        
        // Store updated session
        do {
            try sharedData.storeCurrentWorkoutSession(updatedSession)
            syncCoordinator.syncWorkoutSession(updatedSession)
        } catch {
            AppLogger.error("[WatchWorkoutViewModel] Failed to store updated session: \(error.localizedDescription)", category: "WatchWorkout")
        }
        
        // Update progress
        updateWorkoutProgress()
        
        // Haptic feedback
        WKInterfaceDevice.current().play(.success)
        
        AppLogger.info("[WatchWorkoutViewModel] Completed set \(updatedCompletedSets.count)/\(updatedExercise.plannedSets): \(reps) reps @ \(weight) lbs for \(updatedExercise.name)", category: "WatchWorkout")
    }
    
    private func advanceToNextExercise() {
        guard let session = currentSession else { return }
        
        let nextIndex = min(currentExerciseIndex + 1, session.totalExercises - 1)
        if nextIndex != currentExerciseIndex {
            currentExerciseIndex = nextIndex
            loadCurrentExercise()
            
            // Update session
            updateSessionProgress()
        }
    }
    
    private func goToPreviousExercise() {
        let previousIndex = max(currentExerciseIndex - 1, 0)
        if previousIndex != currentExerciseIndex {
            currentExerciseIndex = previousIndex
            loadCurrentExercise()
            
            // Update session
            updateSessionProgress()
        }
    }
    
    private func completeWorkout() {
        guard let session = currentSession else { return }
        
        // Log completion (sync will be handled by iPhone app)
        AppLogger.info("[WatchWorkoutViewModel] Workout completed: \(session.title)", category: "WatchWorkout")
        
        // Clear local state immediately
        currentSession = nil
        currentExercise = nil
        currentExerciseIndex = 0
        totalExercises = nil
        workoutProgress = nil
        
        // Clear shared data
        sharedData.remove(forKey: .currentWorkoutSession)
        sharedData.remove(forKey: .workoutProgress)
        
        // Stop any running timers
        stopRestTimer()
        
        // Update state to completed
        state = .workoutCompleted
        
        // Haptic feedback
        WKInterfaceDevice.current().play(.success)
        
        // Auto-reset to idle after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.state = .idle
        }
        
        AppLogger.info("[WatchWorkoutViewModel] Workout completed and state cleared", category: "WatchWorkout")
    }
    
    private func cancelWorkout() {
        currentSession = nil
        state = .idle
        stopRestTimer()
        
        // Clear shared data
        sharedData.remove(forKey: .currentWorkoutSession)
        
        AppLogger.info("[WatchWorkoutViewModel] Workout cancelled", category: "WatchWorkout")
    }
    
    // MARK: - Rest Timer Management
    private func startRestTimer(duration: TimeInterval, exerciseName: String?) {
        stopRestTimer() // Stop any existing timer
        
        restTimeRemaining = duration
        isRestTimerRunning = true
        
        // Store timer state and sync
        let timerState = SharedTimerState(
            isRunning: true,
            duration: duration,
            startTime: Date(),
            exerciseName: exerciseName
        )
        
        do {
            try sharedData.storeTimerState(timerState)
            syncCoordinator.syncTimerState(timerState)
        } catch {
            AppLogger.error("[WatchWorkoutViewModel] Failed to store timer state: \(error.localizedDescription)", category: "WatchWorkout")
        }
        
        // Start local timer
        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateRestTimer()
            }
        }
        
        AppLogger.info("[WatchWorkoutViewModel] Rest timer started: \(duration)s", category: "WatchWorkout")
    }
    
    private func stopRestTimer() {
        restTimer?.invalidate()
        restTimer = nil
        isRestTimerRunning = false
        restTimeRemaining = 0
        
        // Update timer state and sync
        let timerState = SharedTimerState(
            isRunning: false,
            duration: 0,
            startTime: nil,
            exerciseName: nil
        )
        
        do {
            try sharedData.storeTimerState(timerState)
            syncCoordinator.syncTimerState(timerState)
        } catch {
            AppLogger.error("[WatchWorkoutViewModel] Failed to stop timer state: \(error.localizedDescription)", category: "WatchWorkout")
        }
    }
    
    private func updateRestTimer() {
        if restTimeRemaining > 0 {
            restTimeRemaining -= 1
        } else {
            // Timer finished
            stopRestTimer()
            WKInterfaceDevice.current().play(.notification)
            AppLogger.info("[WatchWorkoutViewModel] Rest timer completed", category: "WatchWorkout")
        }
    }
    
    // MARK: - Helper Methods
    private func loadCurrentExercise() {
        guard let session = currentSession else {
            currentExercise = nil
            allExercises = []
            return
        }
        
        // Load all exercises from the session
        allExercises = session.exercises
        totalExercises = session.exercises.count
        
        // Set current exercise based on index
        if currentExerciseIndex < allExercises.count {
            currentExercise = allExercises[currentExerciseIndex]
        } else {
            currentExercise = nil
        }
        
        AppLogger.info("[WatchWorkoutViewModel] Loaded \(allExercises.count) exercises, current index: \(currentExerciseIndex)", category: "WatchWorkout")
    }
    
    private func updateWorkoutProgress() {
        guard let session = currentSession else { return }
        
        // Calculate completed sets across all exercises
        let completedSets = session.exercises.reduce(0) { total, exercise in
            total + exercise.completedSets.count
        }
        
        // Calculate total planned sets across all exercises
        let totalSets = session.exercises.reduce(0) { total, exercise in
            total + exercise.plannedSets
        }
        
        // Calculate completed exercises
        let completedExercises = session.exercises.filter { $0.isCompleted }.count
        
        // Estimate time remaining (rough calculation: 2 minutes per remaining set)
        let remainingSets = totalSets - completedSets
        let estimatedTimeRemaining: TimeInterval? = remainingSets > 0 ? TimeInterval(remainingSets * 120) : nil
        
        let progress = SharedWorkoutProgress(
            sessionId: session.id,
            completedSets: completedSets,
            totalSets: totalSets,
            completedExercises: completedExercises,
            totalExercises: session.totalExercises,
            estimatedTimeRemaining: estimatedTimeRemaining
        )
        
        workoutProgress = progress
        
        do {
            try sharedData.storeWorkoutProgress(progress)
            syncCoordinator.syncWorkoutProgress(progress)
        } catch {
            AppLogger.error("[WatchWorkoutViewModel] Failed to update workout progress: \(error.localizedDescription)", category: "WatchWorkout")
        }
        
        AppLogger.info("[WatchWorkoutViewModel] Progress updated: \\(completedSets)/\\(totalSets) sets, \\(completedExercises)/\\(session.totalExercises) exercises", category: "WatchWorkout")
    }
    
    private func updateSessionProgress() {
        guard let session = currentSession else { return }
        
        let updatedSession = SharedWorkoutSession(
            id: session.id,
            title: session.title,
            startTime: session.startTime,
            duration: session.duration,
            currentExerciseIndex: currentExerciseIndex,
            totalExercises: session.totalExercises
        )
        
        currentSession = updatedSession
        
        do {
            try sharedData.storeCurrentWorkoutSession(updatedSession)
            syncCoordinator.syncWorkoutSession(updatedSession)
        } catch {
            AppLogger.error("[WatchWorkoutViewModel] Failed to update session progress: \(error.localizedDescription)", category: "WatchWorkout")
        }
    }
    
    private func fetchWorkoutPlans() async throws -> [WorkoutPlan] {
        // TODO: Implement proper data fetching
        return []
    }
    
    private func createWorkoutSession(from plan: WorkoutPlan) async throws -> SharedWorkoutSession {
        // Create sample exercises for today's workout
        let sampleExercises = [
            SharedSessionExercise(
                id: UUID(),
                exerciseId: UUID(),
                name: "Push-ups",
                category: "Chest",
                plannedSets: 3,
                plannedReps: 12,
                plannedWeight: nil,
                position: 0.0
            ),
            SharedSessionExercise(
                id: UUID(),
                exerciseId: UUID(),
                name: "Squats",
                category: "Legs",
                plannedSets: 3,
                plannedReps: 15,
                plannedWeight: nil,
                position: 1.0
            ),
            SharedSessionExercise(
                id: UUID(),
                exerciseId: UUID(),
                name: "Dumbbell Press",
                category: "Chest",
                plannedSets: 3,
                plannedReps: 10,
                plannedWeight: 25.0,
                position: 2.0
            )
        ]
        
        return SharedWorkoutSession(
            id: UUID(),
            title: plan.customName,
            startTime: Date(),
            duration: nil,
            currentExerciseIndex: 0,
            totalExercises: sampleExercises.count,
            exercises: sampleExercises
        )
    }
    
    // MARK: - Sync Event Handling
    private func handleSyncEvent(_ event: SyncEvent) {
        switch event.type {
        case .workoutStarted:
            if event.deviceSource == .iPhone {
                // Workout started on iPhone, sync to watch
                if let session = sharedData.getCurrentWorkoutSession() {
                    currentSession = session
                    state = .workoutInProgress(session)
                    loadCurrentExercise()
                }
            }
            
        case .workoutCompleted:
            if event.deviceSource == .iPhone {
                state = .workoutCompleted
            }
            
        case .setCompleted:
            updateWorkoutProgress()
            
        case .timerStarted, .timerStopped:
            if event.deviceSource == .iPhone {
                // Timer state changed on iPhone, sync to watch
                if let timerState = sharedData.getTimerState() {
                    if timerState.isRunning && !isRestTimerRunning {
                        restTimeRemaining = timerState.duration
                        isRestTimerRunning = true
                        // Start local timer to keep UI updated
                        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                            Task { @MainActor in
                                self?.updateRestTimer()
                            }
                        }
                    } else if !timerState.isRunning && isRestTimerRunning {
                        stopRestTimer()
                    }
                }
            }
            
        case .exerciseChanged, .progressUpdated:
            if let progress = sharedData.getWorkoutProgress() {
                workoutProgress = progress
            }
            
        case .fullSync:
            loadInitialState()
        }
    }
    
    // MARK: - Cleanup
    deinit {
        // Note: deinit is synchronous, async cleanup should be handled elsewhere
    }
}

// MARK: - Calendar Service Protocol Implementation
public class CalendarService: CalendarProtocol {
    private let calendar = Calendar.current
    
    public init() {}
    
    public func startOfDay(for date: Date) -> Date {
        return calendar.startOfDay(for: date)
    }
    
    public func date(byAdding component: Calendar.Component, value: Int, to date: Date) -> Date? {
        return calendar.date(byAdding: component, value: value, to: date)
    }
    
    public func getCurrentWeekday() -> Weekday {
        let calendar = Calendar.current
        let weekdayIndex = calendar.component(.weekday, from: Date())
        
        switch weekdayIndex {
        case 1: return .sunday
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        case 7: return .saturday
        default: return .monday
        }
    }
}