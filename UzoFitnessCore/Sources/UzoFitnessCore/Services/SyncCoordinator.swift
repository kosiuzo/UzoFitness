import Foundation
import OSLog

// MARK: - Sync State
public enum SyncState {
    case idle
    case syncing
    case error(String)
    case completed
}

// MARK: - Sync Event Types
public enum SyncEventType: Sendable {
    case workoutStarted
    case workoutCompleted
    case setCompleted
    case timerStarted
    case timerStopped
    case exerciseChanged
    case progressUpdated
    case fullSync
}

// MARK: - Sync Event
public struct SyncEvent: Sendable {
    public let type: SyncEventType
    public let timestamp: Date
    public let deviceSource: DeviceSource
    
    public init(type: SyncEventType, deviceSource: DeviceSource) {
        self.type = type
        self.timestamp = Date()
        self.deviceSource = deviceSource
    }
}

public enum DeviceSource: String, Sendable {
    case iPhone = "iPhone"
    case appleWatch = "Apple Watch"
}

// MARK: - Sync Coordinator Protocol
@MainActor
public protocol SyncCoordinatorProtocol: AnyObject {
    var state: SyncState { get }
    var isConnected: Bool { get }
    
    func initialize()
    func syncWorkoutSession(_ session: SharedWorkoutSession)
    func syncSetCompletion(_ completion: SetCompletionPayload)
    func syncTimerState(_ timerState: SharedTimerState)
    func syncWorkoutProgress(_ progress: SharedWorkoutProgress)
    func requestFullSync()
    func handleOfflineOperation(_ event: SyncEvent)
    func processPendingOperations()
    
    // Event handling
    func addSyncEventHandler(_ handler: @escaping (SyncEvent) -> Void)
    func removeSyncEventHandler()
}

// MARK: - Sync Coordinator Implementation
@MainActor
public final class SyncCoordinator: SyncCoordinatorProtocol, ObservableObject {
    
    public static let shared = SyncCoordinator()
    
    @Published public private(set) var state: SyncState = .idle
    
    public var isConnected: Bool {
        watchConnectivity.isReachable
    }
    
    // MARK: - Testing and Validation
    public func sendTestMessage() {
        let testPayload = TestPayload(message: "Test connection from \(getCurrentDeviceSource().rawValue)", timestamp: Date())
        syncToRemoteDevice(.testMessage, payload: testPayload) {
            AppLogger.info("[SyncCoordinator] Test message sent successfully", category: "Sync")
        }
    }
    
    public func validateConnection() -> Bool {
        let isSessionSupported = watchConnectivity.isSessionSupported
        let isReachable = watchConnectivity.isReachable
        let isWatchAppInstalled = watchConnectivity.isWatchAppInstalled
        
        AppLogger.info("[SyncCoordinator] Connection Status - Supported: \(isSessionSupported), Reachable: \(isReachable), App Installed: \(isWatchAppInstalled)", category: "Sync")
        
        // Simplified: Only require session support and reachability
        // App installation check can be unreliable during development
        return isSessionSupported && isReachable
    }
    
    public func sendHeartbeat() {
        let heartbeatPayload = TestPayload(message: "Heartbeat from \(getCurrentDeviceSource().rawValue)", timestamp: Date())
        syncToRemoteDevice(.heartbeat, payload: heartbeatPayload) {
            AppLogger.debug("[SyncCoordinator] Heartbeat sent successfully", category: "Sync")
        }
    }
    
    public func startPeriodicHeartbeat(interval: TimeInterval = 30.0) {
        // Send heartbeat every 30 seconds to maintain connection
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.sendHeartbeat()
            }
        }
        AppLogger.info("[SyncCoordinator] Started periodic heartbeat with interval: \(interval)s", category: "Sync")
    }
    
    private let watchConnectivity: WatchConnectivityProtocol
    private let sharedData: SharedDataProtocol
    private let syncQueue = DispatchQueue(label: "com.kosiuzodinma.UzoFitness.sync", qos: .userInitiated)
    
    private var syncEventHandlers: [(SyncEvent) -> Void] = []
    private var pendingSyncEvents: [SyncEvent] = []
    private var isProcessingSync = false
    private var lastSuccessfulSync: Date?
    
    public init(
        watchConnectivity: WatchConnectivityProtocol = WatchConnectivityManager.shared,
        sharedData: SharedDataProtocol = SharedDataManager.shared
    ) {
        self.watchConnectivity = watchConnectivity
        self.sharedData = sharedData
        
        setupWatchConnectivityDelegate()
        AppLogger.info("[SyncCoordinator] Initialized", category: "Sync")
    }
    
    private func setupWatchConnectivityDelegate() {
        if let watchManager = watchConnectivity as? WatchConnectivityManager {
            watchManager.addDelegate(self)
        }
    }
    
    // MARK: - Initialization
    public func initialize() {
        watchConnectivity.activateSession()
        processPendingOperations()
        AppLogger.info("[SyncCoordinator] Initialized and activated WatchConnectivity", category: "Sync")
    }
    
    // MARK: - Sync Operations
    public func syncWorkoutSession(_ session: SharedWorkoutSession) {
        let payload = WorkoutSessionPayload(
            sessionId: session.id,
            title: session.title,
            duration: session.duration,
            currentExerciseIndex: session.currentExerciseIndex
        )
        
        // Determine the correct message type based on the device
        let message: WatchMessage = .workoutSessionUpdate
        
        syncToRemoteDevice(message, payload: payload) {
            // Store in shared data after successful sync
            do {
                try self.sharedData.storeCurrentWorkoutSession(session)
                self.notifyEventHandlers(.init(type: .workoutStarted, deviceSource: self.getCurrentDeviceSource()))
                AppLogger.info("[SyncCoordinator] Workout session synced and stored locally", category: "Sync")
            } catch {
                AppLogger.error("[SyncCoordinator] Failed to store workout session: \(error.localizedDescription)", category: "Sync")
            }
        }
    }
    
    public func syncWorkoutStart(_ session: SharedWorkoutSession) {
        let payload = WorkoutSessionPayload(
            sessionId: session.id,
            title: session.title,
            duration: session.duration,
            currentExerciseIndex: session.currentExerciseIndex
        )
        
        syncToRemoteDevice(.workoutStarted, payload: payload) {
            do {
                try self.sharedData.storeCurrentWorkoutSession(session)
                self.notifyEventHandlers(.init(type: .workoutStarted, deviceSource: self.getCurrentDeviceSource()))
                AppLogger.info("[SyncCoordinator] Workout start synced successfully", category: "Sync")
            } catch {
                AppLogger.error("[SyncCoordinator] Failed to store workout start: \(error.localizedDescription)", category: "Sync")
            }
        }
    }
    
    public func syncWorkoutCompletion(sessionId: UUID) {
        let payload = WorkoutCompletionPayload(sessionId: sessionId, completedAt: Date())
        
        syncToRemoteDevice(.workoutCompleted, payload: payload) {
            // Clear current workout session after completion
            self.sharedData.remove(forKey: .currentWorkoutSession)
            self.notifyEventHandlers(.init(type: .workoutCompleted, deviceSource: self.getCurrentDeviceSource()))
            AppLogger.info("[SyncCoordinator] Workout completion synced successfully", category: "Sync")
        }
    }
    
    public func syncSetCompletion(_ completion: SetCompletionPayload) {
        syncToRemoteDevice(.setCompleted, payload: completion) {
            // Store as pending in shared data if sync fails
            let pendingCompletion = PendingSetCompletion(
                setId: completion.setId,
                sessionExerciseId: completion.sessionExerciseId,
                reps: completion.reps,
                weight: completion.weight
            )
            
            do {
                try self.sharedData.addPendingSetCompletion(pendingCompletion)
                self.notifyEventHandlers(.init(type: .setCompleted, deviceSource: self.getCurrentDeviceSource()))
            } catch {
                AppLogger.error("[SyncCoordinator] Failed to store pending set completion: \(error.localizedDescription)", category: "Sync")
            }
        }
    }
    
    public func syncTimerState(_ timerState: SharedTimerState) {
        let payload = TimerPayload(
            duration: timerState.duration,
            startTime: timerState.startTime ?? Date(),
            exerciseName: timerState.exerciseName
        )
        
        let eventType: SyncEventType = timerState.isRunning ? .timerStarted : .timerStopped
        let watchMessage: WatchMessage = timerState.isRunning ? .timerStarted : .timerStopped
        
        syncToRemoteDevice(watchMessage, payload: payload) {
            do {
                try self.sharedData.storeTimerState(timerState)
                self.notifyEventHandlers(.init(type: eventType, deviceSource: self.getCurrentDeviceSource()))
                AppLogger.info("[SyncCoordinator] Timer state synced - isRunning: \(timerState.isRunning)", category: "Sync")
            } catch {
                AppLogger.error("[SyncCoordinator] Failed to store timer state: \(error.localizedDescription)", category: "Sync")
            }
        }
    }
    
    public func syncTimerPause(duration: TimeInterval, exerciseName: String?) {
        let timerState = SharedTimerState(
            isRunning: false,
            duration: duration,
            startTime: nil,
            exerciseName: exerciseName
        )
        
        let payload = TimerPayload(
            duration: duration,
            startTime: Date(), // When it was paused
            exerciseName: exerciseName
        )
        
        syncToRemoteDevice(.timerStopped, payload: payload) {
            do {
                try self.sharedData.storeTimerState(timerState)
                self.notifyEventHandlers(.init(type: .timerStopped, deviceSource: self.getCurrentDeviceSource()))
                AppLogger.info("[SyncCoordinator] Timer pause synced successfully", category: "Sync")
            } catch {
                AppLogger.error("[SyncCoordinator] Failed to store timer pause: \(error.localizedDescription)", category: "Sync")
            }
        }
    }
    
    public func syncTimerResume(duration: TimeInterval, exerciseName: String?) {
        let timerState = SharedTimerState(
            isRunning: true,
            duration: duration,
            startTime: Date(),
            exerciseName: exerciseName
        )
        
        let payload = TimerPayload(
            duration: duration,
            startTime: Date(),
            exerciseName: exerciseName
        )
        
        syncToRemoteDevice(.timerStarted, payload: payload) {
            do {
                try self.sharedData.storeTimerState(timerState)
                self.notifyEventHandlers(.init(type: .timerStarted, deviceSource: self.getCurrentDeviceSource()))
                AppLogger.info("[SyncCoordinator] Timer resume synced successfully", category: "Sync")
            } catch {
                AppLogger.error("[SyncCoordinator] Failed to store timer resume: \(error.localizedDescription)", category: "Sync")
            }
        }
    }
    
    public func syncWorkoutProgress(_ progress: SharedWorkoutProgress) {
        syncToRemoteDevice(.currentExerciseUpdate, payload: progress) {
            do {
                try self.sharedData.storeWorkoutProgress(progress)
                self.notifyEventHandlers(.init(type: .progressUpdated, deviceSource: self.getCurrentDeviceSource()))
            } catch {
                AppLogger.error("[SyncCoordinator] Failed to store workout progress: \(error.localizedDescription)", category: "Sync")
            }
        }
    }
    
    public func requestFullSync() {
        guard !isProcessingSync else {
            AppLogger.warning("[SyncCoordinator] Sync already in progress, skipping full sync request", category: "Sync")
            return
        }
        
        isProcessingSync = true
        state = .syncing
        
        watchConnectivity.sendMessage(.syncRequest, payload: nil, replyHandler: { [weak self] response in
            DispatchQueue.main.async {
                self?.handleFullSyncResponse(response)
            }
        }, errorHandler: { [weak self] error in
            DispatchQueue.main.async {
                self?.handleSyncError(error)
            }
        })
        
        AppLogger.info("[SyncCoordinator] Requested full sync", category: "Sync")
    }
    
    // MARK: - Offline Operations
    nonisolated public func handleOfflineOperation(_ event: SyncEvent) {
        Task { @MainActor in
            // Avoid duplicate events
            let isDuplicate = pendingSyncEvents.contains { existingEvent in
                existingEvent.type == event.type && 
                existingEvent.deviceSource == event.deviceSource &&
                abs(existingEvent.timestamp.timeIntervalSince(event.timestamp)) < 1.0 // Within 1 second
            }
            
            if !isDuplicate {
                pendingSyncEvents.append(event)
                AppLogger.debug("[SyncCoordinator] Queued offline operation: \(event.type)", category: "Sync")
            } else {
                AppLogger.debug("[SyncCoordinator] Skipped duplicate offline operation: \(event.type)", category: "Sync")
            }
        }
    }
    
    public func clearPendingOperations() {
        pendingSyncEvents.removeAll()
        AppLogger.info("[SyncCoordinator] Cleared all pending sync operations", category: "Sync")
    }
    
    public func getPendingOperationsCount() -> Int {
        return pendingSyncEvents.count
    }
    
    public func processPendingOperations() {
        guard isConnected else {
            AppLogger.debug("[SyncCoordinator] Device not connected, keeping operations pending", category: "Sync")
            return
        }
        
        // Sort events by timestamp to maintain chronological order
        let eventsToProcess = pendingSyncEvents.sorted { $0.timestamp < $1.timestamp }
        pendingSyncEvents.removeAll()
        
        // Group events by type to handle conflicts
        var eventGroups: [SyncEventType: [SyncEvent]] = [:]
        for event in eventsToProcess {
            eventGroups[event.type, default: []].append(event)
        }
        
        // Process events with conflict resolution
        for (eventType, events) in eventGroups {
            switch eventType {
            case .workoutStarted, .workoutCompleted:
                // Only process the most recent workout event
                if let latestEvent = events.max(by: { $0.timestamp < $1.timestamp }) {
                    processPendingEvent(latestEvent)
                }
            case .timerStarted, .timerStopped:
                // Only process the most recent timer event  
                if let latestEvent = events.max(by: { $0.timestamp < $1.timestamp }) {
                    processPendingEvent(latestEvent)
                }
            case .setCompleted:
                // Process all set completions (no conflicts expected)
                for event in events {
                    processPendingEvent(event)
                }
            default:
                // Process all other events in chronological order
                for event in events.sorted(by: { $0.timestamp < $1.timestamp }) {
                    processPendingEvent(event)
                }
            }
        }
        
        if !eventsToProcess.isEmpty {
            AppLogger.info("[SyncCoordinator] Processed \(eventsToProcess.count) pending sync events with conflict resolution", category: "Sync")
        }
        
        // Process pending set completions
        let pendingCompletions = sharedData.getPendingSetCompletions()
        for completion in pendingCompletions {
            let payload = SetCompletionPayload(
                setId: completion.setId,
                sessionExerciseId: completion.sessionExerciseId,
                reps: completion.reps,
                weight: completion.weight,
                isCompleted: true
            )
            
            syncToRemoteDevice(.setCompleted, payload: payload) {
                self.sharedData.removePendingSetCompletion(withId: completion.id)
            }
        }
    }
    
    private func processPendingEvent(_ event: SyncEvent) {
        switch event.type {
        case .workoutStarted:
            if let session = sharedData.getCurrentWorkoutSession() {
                syncWorkoutSession(session)
            }
        case .setCompleted:
            // Handled by pending set completions
            break
        case .timerStarted, .timerStopped:
            if let timerState = sharedData.getTimerState() {
                syncTimerState(timerState)
            }
        case .progressUpdated:
            if let progress = sharedData.getWorkoutProgress() {
                syncWorkoutProgress(progress)
            }
        case .workoutCompleted, .exerciseChanged, .fullSync:
            // These require more complex handling
            break
        }
    }
    
    // MARK: - Helper Methods
    private func syncToRemoteDevice<T: Codable>(_ message: WatchMessage, payload: T, onSuccess: @escaping () -> Void) {
        guard isConnected else {
            // Store for later sync
            let event = SyncEvent(type: messageToEventType(message), deviceSource: getCurrentDeviceSource())
            handleOfflineOperation(event)
            onSuccess() // Still call success to update local state
            return
        }
        
        state = .syncing
        
        watchConnectivity.sendPayload(message, payload: payload, replyHandler: { [weak self] response in
            DispatchQueue.main.async {
                self?.state = .completed
                self?.lastSuccessfulSync = Date()
                onSuccess()
                AppLogger.debug("[SyncCoordinator] Successfully synced \(message.rawValue)", category: "Sync")
                
                // Reset to idle after a brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self?.state = .idle
                }
            }
        }, errorHandler: { [weak self] error in
            DispatchQueue.main.async {
                self?.handleSyncError(error)
                onSuccess() // Still update local state even if sync fails
            }
        })
    }
    
    private func handleFullSyncResponse(_ response: [String: Any]) {
        // Process full sync response
        state = .completed
        isProcessingSync = false
        lastSuccessfulSync = Date()
        
        // Reset to idle after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.state = .idle
        }
        
        AppLogger.info("[SyncCoordinator] Completed full sync", category: "Sync")
    }
    
    private func handleSyncError(_ error: Error) {
        state = .error(error.localizedDescription)
        isProcessingSync = false
        
        AppLogger.error("[SyncCoordinator] Sync error: \(error.localizedDescription)", category: "Sync")
        
        // Reset to idle after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.state = .idle
        }
    }
    
    private func messageToEventType(_ message: WatchMessage) -> SyncEventType {
        switch message {
        case .workoutStarted:
            return .workoutStarted
        case .workoutCompleted:
            return .workoutCompleted
        case .setCompleted:
            return .setCompleted
        case .timerStarted:
            return .timerStarted
        case .timerStopped:
            return .timerStopped
        case .currentExerciseUpdate:
            return .exerciseChanged
        case .syncRequest:
            return .fullSync
        case .testMessage:
            return .progressUpdated
        default:
            return .progressUpdated
        }
    }
    
    private func getCurrentDeviceSource() -> DeviceSource {
        #if os(iOS)
        return .iPhone
        #elseif os(watchOS)
        return .appleWatch
        #else
        return .iPhone
        #endif
    }
    
    // MARK: - Event Handling
    public func addSyncEventHandler(_ handler: @escaping (SyncEvent) -> Void) {
        syncEventHandlers.append(handler)
    }
    
    public func removeSyncEventHandler() {
        syncEventHandlers.removeAll()
    }
    
    private func notifyEventHandlers(_ event: SyncEvent) {
        for handler in syncEventHandlers {
            handler(event)
        }
    }
}

// MARK: - WatchConnectivityDelegate
extension SyncCoordinator: WatchConnectivityDelegate {
    
    public func didReceiveMessage(_ message: WatchMessage, payload: Data?) {
        AppLogger.debug("[SyncCoordinator] Received message: \(message.rawValue)", category: "Sync")
        
        switch message {
        case .workoutSessionUpdate:
            handleWorkoutSessionUpdate(payload)
        case .workoutStarted:
            handleWorkoutStarted(payload)
        case .workoutCompleted:
            handleWorkoutCompleted(payload)
        case .setCompleted:
            handleSetCompletion(payload)
        case .timerStarted, .timerStopped:
            handleTimerUpdate(message, payload)
        case .currentExerciseUpdate:
            handleExerciseUpdate(payload)
        case .syncRequest:
            handleSyncRequest()
        case .heartbeat:
            handleHeartbeat()
        case .testMessage:
            handleTestMessage(payload)
        default:
            AppLogger.debug("[SyncCoordinator] Unhandled message type: \(message.rawValue)", category: "Sync")
        }
    }
    
    private func handleWorkoutSessionUpdate(_ payload: Data?) {
        guard let payload = payload else { return }
        
        do {
            let sessionPayload = try JSONDecoder().decode(WorkoutSessionPayload.self, from: payload)
            let sharedSession = SharedWorkoutSession(
                id: sessionPayload.sessionId,
                title: sessionPayload.title,
                startTime: Date(), // Approximate start time
                duration: sessionPayload.duration,
                currentExerciseIndex: sessionPayload.currentExerciseIndex ?? 0,
                totalExercises: 0 // Will be updated with more data
            )
            
            try sharedData.storeCurrentWorkoutSession(sharedSession)
            let deviceSource = getCurrentDeviceSource() == .iPhone ? DeviceSource.appleWatch : DeviceSource.iPhone
            notifyEventHandlers(.init(type: .workoutStarted, deviceSource: deviceSource))
            AppLogger.info("[SyncCoordinator] Workout session updated from remote device", category: "Sync")
            
        } catch {
            AppLogger.error("[SyncCoordinator] Failed to handle workout session update: \(error.localizedDescription)", category: "Sync")
        }
    }
    
    private func handleWorkoutStarted(_ payload: Data?) {
        guard let payload = payload else { return }
        
        do {
            let sessionPayload = try JSONDecoder().decode(WorkoutSessionPayload.self, from: payload)
            let sharedSession = SharedWorkoutSession(
                id: sessionPayload.sessionId,
                title: sessionPayload.title,
                startTime: Date(),
                duration: sessionPayload.duration,
                currentExerciseIndex: sessionPayload.currentExerciseIndex ?? 0,
                totalExercises: 0
            )
            
            try sharedData.storeCurrentWorkoutSession(sharedSession)
            let deviceSource = getCurrentDeviceSource() == .iPhone ? DeviceSource.appleWatch : DeviceSource.iPhone
            notifyEventHandlers(.init(type: .workoutStarted, deviceSource: deviceSource))
            AppLogger.info("[SyncCoordinator] Workout started from remote device", category: "Sync")
            
        } catch {
            AppLogger.error("[SyncCoordinator] Failed to handle workout start: \(error.localizedDescription)", category: "Sync")
        }
    }
    
    private func handleWorkoutCompleted(_ payload: Data?) {
        guard let payload = payload else { return }
        
        do {
            let completionPayload = try JSONDecoder().decode(WorkoutCompletionPayload.self, from: payload)
            
            // Clear the current workout session
            sharedData.remove(forKey: .currentWorkoutSession)
            
            let deviceSource = getCurrentDeviceSource() == .iPhone ? DeviceSource.appleWatch : DeviceSource.iPhone
            notifyEventHandlers(.init(type: .workoutCompleted, deviceSource: deviceSource))
            AppLogger.info("[SyncCoordinator] Workout completed from remote device: \(completionPayload.sessionId)", category: "Sync")
            
        } catch {
            AppLogger.error("[SyncCoordinator] Failed to handle workout completion: \(error.localizedDescription)", category: "Sync")
        }
    }
    
    private func handleSetCompletion(_ payload: Data?) {
        guard let payload = payload else { return }
        
        do {
            let completion = try JSONDecoder().decode(SetCompletionPayload.self, from: payload)
            
            // Store as pending completion for processing by the main app
            let pendingCompletion = PendingSetCompletion(
                setId: completion.setId,
                sessionExerciseId: completion.sessionExerciseId,
                reps: completion.reps,
                weight: completion.weight
            )
            
            try sharedData.addPendingSetCompletion(pendingCompletion)
            let deviceSource = getCurrentDeviceSource() == .iPhone ? DeviceSource.appleWatch : DeviceSource.iPhone
            notifyEventHandlers(.init(type: .setCompleted, deviceSource: deviceSource))
            
        } catch {
            AppLogger.error("[SyncCoordinator] Failed to handle set completion: \(error.localizedDescription)", category: "Sync")
        }
    }
    
    private func handleTimerUpdate(_ message: WatchMessage, _ payload: Data?) {
        guard let payload = payload else { return }
        
        do {
            let timerPayload = try JSONDecoder().decode(TimerPayload.self, from: payload)
            let timerState = SharedTimerState(
                isRunning: message == .timerStarted,
                duration: timerPayload.duration,
                startTime: timerPayload.startTime,
                exerciseName: timerPayload.exerciseName
            )
            
            try sharedData.storeTimerState(timerState)
            
            let eventType: SyncEventType = message == .timerStarted ? .timerStarted : .timerStopped
            let deviceSource = getCurrentDeviceSource() == .iPhone ? DeviceSource.appleWatch : DeviceSource.iPhone
            notifyEventHandlers(.init(type: eventType, deviceSource: deviceSource))
            
        } catch {
            AppLogger.error("[SyncCoordinator] Failed to handle timer update: \(error.localizedDescription)", category: "Sync")
        }
    }
    
    private func handleExerciseUpdate(_ payload: Data?) {
        guard let payload = payload else { return }
        
        // Handle exercise/progress updates
        let deviceSource = getCurrentDeviceSource() == .iPhone ? DeviceSource.appleWatch : DeviceSource.iPhone
        notifyEventHandlers(.init(type: .exerciseChanged, deviceSource: deviceSource))
    }
    
    private func handleSyncRequest() {
        // Respond with current state
        requestFullSync()
    }
    
    private func handleHeartbeat() {
        // Connection is alive, process any pending operations
        processPendingOperations()
    }
    
    private func handleTestMessage(_ payload: Data?) {
        guard let payload = payload else { return }
        
        do {
            let testPayload = try JSONDecoder().decode(TestPayload.self, from: payload)
            AppLogger.info("[SyncCoordinator] Received test message: '\(testPayload.message)' at \(testPayload.timestamp)", category: "Sync")
            
            // Echo back a response
            let responsePayload = TestPayload(
                message: "Test response from \(getCurrentDeviceSource().rawValue)",
                timestamp: Date()
            )
            
            syncToRemoteDevice(.testMessage, payload: responsePayload) {
                AppLogger.info("[SyncCoordinator] Sent test response successfully", category: "Sync")
            }
            
        } catch {
            AppLogger.error("[SyncCoordinator] Failed to handle test message: \(error.localizedDescription)", category: "Sync")
        }
    }
    
    public func sessionDidBecomeInactive() {
        AppLogger.info("[SyncCoordinator] WatchConnectivity session became inactive", category: "Sync")
    }
    
    public func sessionDidDeactivate() {
        AppLogger.info("[SyncCoordinator] WatchConnectivity session deactivated", category: "Sync")
    }
    
    public func sessionWatchStateDidChange() {
        AppLogger.info("[SyncCoordinator] Watch state changed", category: "Sync")
        if isConnected {
            processPendingOperations()
        }
    }
}