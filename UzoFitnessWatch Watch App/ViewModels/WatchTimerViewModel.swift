import Foundation
import Combine
import WatchKit
import UzoFitnessCore

// MARK: - Timer Intent Actions
enum TimerIntent {
    case startTimer(duration: TimeInterval, exerciseName: String?)
    case pauseTimer
    case resumeTimer
    case stopTimer
    case addTime(seconds: TimeInterval)
    case subtractTime(seconds: TimeInterval)
}

// MARK: - Timer State
enum TimerState {
    case idle
    case running(timeRemaining: TimeInterval, exerciseName: String?)
    case paused(timeRemaining: TimeInterval, exerciseName: String?)
    case completed(exerciseName: String?)
}

// MARK: - Watch Timer ViewModel
@MainActor
public final class WatchTimerViewModel: ObservableObject {
    
    // MARK: - Published State
    @Published var state: TimerState = .idle
    @Published var formattedTime: String = "0:00"
    @Published var progress: Double = 0.0
    @Published var isConnected: Bool = false
    
    // MARK: - Timer Presets
    public let timerPresets: [TimeInterval] = [30, 60, 90, 120, 180]
    
    // MARK: - Dependencies
    private let syncCoordinator: SyncCoordinatorProtocol
    private let sharedData: SharedDataProtocol
    
    // MARK: - Private State
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var totalDuration: TimeInterval = 0
    private var startTime: Date?
    
    // MARK: - Initialization
    public init(
        syncCoordinator: SyncCoordinatorProtocol,
        sharedData: SharedDataProtocol = SharedDataManager.shared
    ) {
        self.syncCoordinator = syncCoordinator
        self.sharedData = sharedData
        
        setupObservers()
        loadTimerState()
    }
    
    // MARK: - Setup
    private func setupObservers() {
        // Observe connection status
        isConnected = syncCoordinator.isConnected
        
        // Add sync event handler for timer events
        syncCoordinator.addSyncEventHandler { [weak self] event in
            self?.handleSyncEvent(event)
        }
    }
    
    private func loadTimerState() {
        // Check if there's an existing timer state
        if let timerState = sharedData.getTimerState(), timerState.isRunning {
            if let startTime = timerState.startTime {
                let elapsed = Date().timeIntervalSince(startTime)
                let remaining = max(0, timerState.duration - elapsed)
                
                if remaining > 0 {
                    totalDuration = timerState.duration
                    state = .running(timeRemaining: remaining, exerciseName: timerState.exerciseName)
                    startLocalTimer()
                } else {
                    state = .completed(exerciseName: timerState.exerciseName)
                }
            }
        }
        updateDisplayValues()
    }
    
    // MARK: - Intent Handling
    func handle(_ intent: TimerIntent) {
        switch intent {
        case .startTimer(let duration, let exerciseName):
            startTimer(duration: duration, exerciseName: exerciseName)
            
        case .pauseTimer:
            pauseTimer()
            
        case .resumeTimer:
            resumeTimer()
            
        case .stopTimer:
            stopTimer()
            
        case .addTime(let seconds):
            addTime(seconds: seconds)
            
        case .subtractTime(let seconds):
            subtractTime(seconds: seconds)
        }
    }
    
    // MARK: - Timer Management
    private func startTimer(duration: TimeInterval, exerciseName: String?) {
        stopLocalTimer()
        
        totalDuration = duration
        startTime = Date()
        state = .running(timeRemaining: duration, exerciseName: exerciseName)
        
        // Store timer state and sync
        let timerState = SharedTimerState(
            isRunning: true,
            duration: duration,
            startTime: startTime,
            exerciseName: exerciseName
        )
        
        syncTimerState(timerState)
        startLocalTimer()
        updateDisplayValues()
        
        AppLogger.info("[WatchTimerViewModel] Timer started: \(duration)s for \(exerciseName ?? "unknown exercise")", category: "WatchTimer")
    }
    
    private func pauseTimer() {
        guard case .running(let timeRemaining, let exerciseName) = state else { return }
        
        stopLocalTimer()
        state = .paused(timeRemaining: timeRemaining, exerciseName: exerciseName)
        
        // Update timer state and sync
        let timerState = SharedTimerState(
            isRunning: false,
            duration: timeRemaining,
            startTime: nil,
            exerciseName: exerciseName
        )
        
        syncTimerState(timerState)
        updateDisplayValues()
        
        AppLogger.info("[WatchTimerViewModel] Timer paused", category: "WatchTimer")
    }
    
    private func resumeTimer() {
        guard case .paused(let timeRemaining, let exerciseName) = state else { return }
        
        startTime = Date()
        state = .running(timeRemaining: timeRemaining, exerciseName: exerciseName)
        
        // Update timer state and sync
        let timerState = SharedTimerState(
            isRunning: true,
            duration: timeRemaining,
            startTime: startTime,
            exerciseName: exerciseName
        )
        
        syncTimerState(timerState)
        startLocalTimer()
        updateDisplayValues()
        
        AppLogger.info("[WatchTimerViewModel] Timer resumed", category: "WatchTimer")
    }
    
    private func stopTimer() {
        stopLocalTimer()
        state = .idle
        totalDuration = 0
        startTime = nil
        
        // Clear timer state and sync
        let timerState = SharedTimerState(
            isRunning: false,
            duration: 0,
            startTime: nil,
            exerciseName: nil
        )
        
        syncTimerState(timerState)
        updateDisplayValues()
        
        AppLogger.info("[WatchTimerViewModel] Timer stopped", category: "WatchTimer")
    }
    
    private func addTime(seconds: TimeInterval) {
        switch state {
        case .running(let timeRemaining, let exerciseName):
            let newTimeRemaining = timeRemaining + seconds
            totalDuration += seconds
            state = .running(timeRemaining: newTimeRemaining, exerciseName: exerciseName)
            
        case .paused(let timeRemaining, let exerciseName):
            let newTimeRemaining = timeRemaining + seconds
            totalDuration += seconds
            state = .paused(timeRemaining: newTimeRemaining, exerciseName: exerciseName)
            
        default:
            break
        }
        
        updateDisplayValues()
        syncCurrentTimerState()
    }
    
    private func subtractTime(seconds: TimeInterval) {
        switch state {
        case .running(let timeRemaining, let exerciseName):
            let newTimeRemaining = max(0, timeRemaining - seconds)
            totalDuration = max(0, totalDuration - seconds)
            
            if newTimeRemaining == 0 {
                timerCompleted(exerciseName: exerciseName)
            } else {
                state = .running(timeRemaining: newTimeRemaining, exerciseName: exerciseName)
            }
            
        case .paused(let timeRemaining, let exerciseName):
            let newTimeRemaining = max(0, timeRemaining - seconds)
            totalDuration = max(0, totalDuration - seconds)
            
            if newTimeRemaining == 0 {
                state = .idle
            } else {
                state = .paused(timeRemaining: newTimeRemaining, exerciseName: exerciseName)
            }
            
        default:
            break
        }
        
        updateDisplayValues()
        syncCurrentTimerState()
    }
    
    // MARK: - Local Timer Management
    private func startLocalTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateTimer()
            }
        }
    }
    
    private func stopLocalTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateTimer() {
        guard case .running(let timeRemaining, let exerciseName) = state else {
            stopLocalTimer()
            return
        }
        
        let newTimeRemaining = max(0, timeRemaining - 1)
        
        if newTimeRemaining == 0 {
            timerCompleted(exerciseName: exerciseName)
        } else {
            state = .running(timeRemaining: newTimeRemaining, exerciseName: exerciseName)
            updateDisplayValues()
        }
    }
    
    private func timerCompleted(exerciseName: String?) {
        stopLocalTimer()
        state = .completed(exerciseName: exerciseName)
        
        // Clear timer state and sync
        let timerState = SharedTimerState(
            isRunning: false,
            duration: 0,
            startTime: nil,
            exerciseName: nil
        )
        
        syncTimerState(timerState)
        updateDisplayValues()
        
        // Haptic feedback and notification
        WKInterfaceDevice.current().play(.notification)
        
        AppLogger.info("[WatchTimerViewModel] Timer completed for \(exerciseName ?? "unknown exercise")", category: "WatchTimer")
    }
    
    // MARK: - Display Updates
    private func updateDisplayValues() {
        let timeRemaining: TimeInterval
        
        switch state {
        case .running(let remaining, _), .paused(let remaining, _):
            timeRemaining = remaining
        case .completed(_):
            timeRemaining = 0
        case .idle:
            timeRemaining = 0
        }
        
        formattedTime = formatTime(timeRemaining)
        progress = totalDuration > 0 ? max(0, 1.0 - (timeRemaining / totalDuration)) : 0.0
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Sync Management
    private func syncTimerState(_ timerState: SharedTimerState) {
        do {
            try sharedData.storeTimerState(timerState)
            syncCoordinator.syncTimerState(timerState)
        } catch {
            AppLogger.error("[WatchTimerViewModel] Failed to sync timer state: \(error.localizedDescription)", category: "WatchTimer")
        }
    }
    
    private func syncCurrentTimerState() {
        let timerState: SharedTimerState
        
        switch state {
        case .running(let timeRemaining, let exerciseName):
            timerState = SharedTimerState(
                isRunning: true,
                duration: timeRemaining,
                startTime: startTime,
                exerciseName: exerciseName
            )
            
        case .paused(let timeRemaining, let exerciseName):
            timerState = SharedTimerState(
                isRunning: false,
                duration: timeRemaining,
                startTime: nil,
                exerciseName: exerciseName
            )
            
        default:
            timerState = SharedTimerState(
                isRunning: false,
                duration: 0,
                startTime: nil,
                exerciseName: nil
            )
        }
        
        syncTimerState(timerState)
    }
    
    // MARK: - Sync Event Handling
    private func handleSyncEvent(_ event: SyncEvent) {
        switch event.type {
        case .timerStarted, .timerStopped:
            if event.deviceSource == .iPhone {
                // Timer state changed on iPhone, sync to watch
                loadTimerState()
            }
            
        default:
            break
        }
    }
    
    // MARK: - Public Helpers
    public func quickStartTimer(duration: TimeInterval) {
        handle(.startTimer(duration: duration, exerciseName: nil))
    }
    
    public func getPresetLabel(for duration: TimeInterval) -> String {
        if duration < 60 {
            return "\(Int(duration))s"
        } else {
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            return seconds == 0 ? "\(minutes)m" : "\(minutes)m \(seconds)s"
        }
    }
    
    // MARK: - Cleanup
    deinit {
        // Note: deinit is synchronous, async cleanup should be handled elsewhere
    }
}