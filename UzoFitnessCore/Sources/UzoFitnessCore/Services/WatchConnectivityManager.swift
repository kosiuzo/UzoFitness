import Foundation
import WatchConnectivity
import OSLog

// MARK: - Message Types
public enum WatchMessage: String, CaseIterable, Codable {
    case workoutSessionUpdate = "workoutSessionUpdate"
    case setCompleted = "setCompleted"
    case timerStarted = "timerStarted"
    case timerStopped = "timerStopped"
    case workoutCompleted = "workoutCompleted"
    case workoutStarted = "workoutStarted"
    case currentExerciseUpdate = "currentExerciseUpdate"
    case syncRequest = "syncRequest"
    case heartbeat = "heartbeat"
    case testMessage = "testMessage"
}

// MARK: - Message Payloads
public struct WorkoutSessionPayload: Codable {
    public let sessionId: UUID
    public let title: String
    public let duration: TimeInterval?
    public let currentExerciseIndex: Int?
    
    public init(sessionId: UUID, title: String, duration: TimeInterval?, currentExerciseIndex: Int?) {
        self.sessionId = sessionId
        self.title = title
        self.duration = duration
        self.currentExerciseIndex = currentExerciseIndex
    }
}

public struct SetCompletionPayload: Codable {
    public let setId: UUID
    public let sessionExerciseId: UUID
    public let reps: Int
    public let weight: Double
    public let isCompleted: Bool
    
    public init(setId: UUID, sessionExerciseId: UUID, reps: Int, weight: Double, isCompleted: Bool) {
        self.setId = setId
        self.sessionExerciseId = sessionExerciseId
        self.reps = reps
        self.weight = weight
        self.isCompleted = isCompleted
    }
}

public struct TimerPayload: Codable {
    public let duration: TimeInterval
    public let startTime: Date
    public let exerciseName: String?
    
    public init(duration: TimeInterval, startTime: Date, exerciseName: String?) {
        self.duration = duration
        self.startTime = startTime
        self.exerciseName = exerciseName
    }
}

public struct CurrentExercisePayload: Codable {
    public let exerciseId: UUID
    public let exerciseName: String
    public let currentSetIndex: Int
    public let totalSets: Int
    public let isInSuperset: Bool
    public let supersetExercises: [String]?
    
    public init(exerciseId: UUID, exerciseName: String, currentSetIndex: Int, totalSets: Int, isInSuperset: Bool, supersetExercises: [String]?) {
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.currentSetIndex = currentSetIndex
        self.totalSets = totalSets
        self.isInSuperset = isInSuperset
        self.supersetExercises = supersetExercises
    }
}

public struct TestPayload: Codable {
    public let message: String
    public let timestamp: Date
    
    public init(message: String, timestamp: Date) {
        self.message = message
        self.timestamp = timestamp
    }
}

public struct WorkoutCompletionPayload: Codable {
    public let sessionId: UUID
    public let completedAt: Date
    
    public init(sessionId: UUID, completedAt: Date) {
        self.sessionId = sessionId
        self.completedAt = completedAt
    }
}

// MARK: - WatchConnectivity Protocol
@MainActor
public protocol WatchConnectivityProtocol: AnyObject {
    var isReachable: Bool { get }
    var isWatchAppInstalled: Bool { get }
    var isSessionSupported: Bool { get }
    
    func activateSession()
    func sendMessage(_ message: WatchMessage, payload: Data?, replyHandler: (([String: Any]) -> Void)?, errorHandler: ((Error) -> Void)?)
    func sendPayload<T: Codable>(_ message: WatchMessage, payload: T, replyHandler: (([String: Any]) -> Void)?, errorHandler: ((Error) -> Void)?)
    func updateApplicationContext(_ context: [String: Any]) throws
    
    // Delegate methods
    func didReceiveMessage(_ message: WatchMessage, payload: Data?)
    func didReceiveApplicationContextUpdate(_ context: [String: Any])
    func sessionDidBecomeInactive()
    func sessionDidDeactivate()
    func sessionWatchStateDidChange()
}

// MARK: - WatchConnectivity Manager
@MainActor
public final class WatchConnectivityManager: NSObject, WatchConnectivityProtocol, ObservableObject {
    
    public static let shared = WatchConnectivityManager()
    
    @Published public private(set) var isReachable: Bool = false
    @Published public private(set) var isWatchAppInstalled: Bool = false
    @Published public private(set) var connectionState: ConnectionState = .disconnected
    
    public var isSessionSupported: Bool {
        WCSession.isSupported()
    }
    
    private var session: WCSession?
    private let syncQueue = DispatchQueue(label: "com.kosiuzodinma.UzoFitness.watchSync", qos: .utility)
    private var pendingMessages: [PendingMessage] = []
    private var delegates: [WeakDelegate] = []
    
    public enum ConnectionState {
        case disconnected
        case connecting
        case connected
        case error(String)
    }
    
    private struct PendingMessage {
        let message: WatchMessage
        let payload: Data?
        let timestamp: Date
        let replyHandler: (([String: Any]) -> Void)?
        let errorHandler: ((Error) -> Void)?
    }
    
    private struct WeakDelegate {
        weak var delegate: WatchConnectivityDelegate?
    }
    
    private override init() {
        super.init()
        setupSession()
    }
    
    // MARK: - Session Setup
    private func setupSession() {
        guard WCSession.isSupported() else {
            AppLogger.warning("[WatchConnectivityManager] WatchConnectivity not supported on this device", category: "WatchConnectivity")
            connectionState = .error("WatchConnectivity not supported")
            return
        }
        
        session = WCSession.default
        session?.delegate = self
        AppLogger.info("[WatchConnectivityManager] WatchConnectivity session configured", category: "WatchConnectivity")
    }
    
    public func activateSession() {
        guard let session = session else {
            AppLogger.error("[WatchConnectivityManager] No WCSession available", category: "WatchConnectivity")
            connectionState = .error("No WCSession available")
            return
        }
        
        connectionState = .connecting
        session.activate()
        AppLogger.info("[WatchConnectivityManager] Activating WatchConnectivity session", category: "WatchConnectivity")
    }
    
    // MARK: - Message Sending
    public func sendMessage(_ message: WatchMessage, payload: Data?, replyHandler: (([String: Any]) -> Void)?, errorHandler: ((Error) -> Void)?) {
        guard let session = session, session.isReachable else {
            AppLogger.warning("[WatchConnectivityManager] Session not reachable, queuing message: \(message.rawValue)", category: "WatchConnectivity")
            queueMessage(message, payload: payload, replyHandler: replyHandler, errorHandler: errorHandler)
            return
        }
        
        let messageDict: [String: Any] = [
            "type": message.rawValue,
            "payload": payload ?? Data(),
            "timestamp": Date().timeIntervalSince1970
        ]
        
        session.sendMessage(messageDict, replyHandler: replyHandler, errorHandler: { error in
            AppLogger.error("[WatchConnectivityManager] Failed to send message \(message.rawValue): \(error.localizedDescription)", category: "WatchConnectivity")
            errorHandler?(error)
        })
        
        AppLogger.debug("[WatchConnectivityManager] Sent message: \(message.rawValue)", category: "WatchConnectivity")
    }
    
    public func sendPayload<T: Codable>(_ message: WatchMessage, payload: T, replyHandler: (([String: Any]) -> Void)?, errorHandler: ((Error) -> Void)?) {
        do {
            let data = try JSONEncoder().encode(payload)
            sendMessage(message, payload: data, replyHandler: replyHandler, errorHandler: errorHandler)
        } catch {
            AppLogger.error("[WatchConnectivityManager] Failed to encode payload for message \(message.rawValue): \(error.localizedDescription)", category: "WatchConnectivity")
            errorHandler?(error)
        }
    }
    
    public func updateApplicationContext(_ context: [String: Any]) throws {
        guard let session = session else {
            throw WatchConnectivityError.sessionNotAvailable
        }
        
        try session.updateApplicationContext(context)
        AppLogger.debug("[WatchConnectivityManager] Updated application context", category: "WatchConnectivity")
    }
    
    // MARK: - Message Queuing
    private func queueMessage(_ message: WatchMessage, payload: Data?, replyHandler: (([String: Any]) -> Void)?, errorHandler: ((Error) -> Void)?) {
        let pendingMessage = PendingMessage(
            message: message,
            payload: payload,
            timestamp: Date(),
            replyHandler: replyHandler,
            errorHandler: errorHandler
        )
        
        pendingMessages.append(pendingMessage)
        // Remove old messages (older than 5 minutes)
        let cutoffTime = Date().addingTimeInterval(-300)
        pendingMessages.removeAll { $0.timestamp < cutoffTime }
        
        AppLogger.debug("[WatchConnectivityManager] Queued message: \(message.rawValue)", category: "WatchConnectivity")
    }
    
    private func processPendingMessages() {
        guard let session = session, session.isReachable else { return }
        
        let messagesToProcess = pendingMessages
        pendingMessages.removeAll()
        
        for pendingMessage in messagesToProcess {
            sendMessage(
                pendingMessage.message,
                payload: pendingMessage.payload,
                replyHandler: pendingMessage.replyHandler,
                errorHandler: pendingMessage.errorHandler
            )
        }
        
        if !messagesToProcess.isEmpty {
            AppLogger.info("[WatchConnectivityManager] Processed \(messagesToProcess.count) pending messages", category: "WatchConnectivity")
        }
    }
    
    // MARK: - Delegate Management
    public func addDelegate(_ delegate: WatchConnectivityDelegate) {
        delegates.append(WeakDelegate(delegate: delegate))
        // Clean up nil delegates
        delegates.removeAll { $0.delegate == nil }
    }
    
    public func removeDelegate(_ delegate: WatchConnectivityDelegate) {
        delegates.removeAll { $0.delegate === delegate }
    }
    
    // MARK: - Protocol Implementation (Called by delegates)
    public func didReceiveMessage(_ message: WatchMessage, payload: Data?) {
        Task { @MainActor in
            delegates.forEach { $0.delegate?.didReceiveMessage(message, payload: payload) }
        }
    }
    
    public func didReceiveApplicationContextUpdate(_ context: [String: Any]) {
        Task { @MainActor in
            delegates.forEach { $0.delegate?.didReceiveApplicationContextUpdate(context) }
        }
    }
    
    public func sessionDidBecomeInactive() {
        Task { @MainActor in
            connectionState = .disconnected
            delegates.forEach { $0.delegate?.sessionDidBecomeInactive() }
        }
    }
    
    public func sessionDidDeactivate() {
        Task { @MainActor in
            connectionState = .disconnected
            delegates.forEach { $0.delegate?.sessionDidDeactivate() }
        }
    }
    
    public func sessionWatchStateDidChange() {
        Task { @MainActor in
            delegates.forEach { $0.delegate?.sessionWatchStateDidChange() }
        }
    }
}

// MARK: - WCSessionDelegate
extension WatchConnectivityManager: WCSessionDelegate {
    
    #if os(iOS)
    nonisolated public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        let isReachable = session.isReachable
        let isWatchAppInstalled = session.isWatchAppInstalled
        
        Task { @MainActor in
            switch activationState {
            case .activated:
                self.connectionState = .connected
                self.isReachable = isReachable
                self.isWatchAppInstalled = isWatchAppInstalled
                self.processPendingMessages()
                AppLogger.info("[WatchConnectivityManager] Session activated successfully", category: "WatchConnectivity")
                
            case .inactive:
                self.connectionState = .disconnected
                AppLogger.warning("[WatchConnectivityManager] Session activated but is inactive", category: "WatchConnectivity")
                
            case .notActivated:
                self.connectionState = .error("Session not activated")
                AppLogger.error("[WatchConnectivityManager] Session activation failed", category: "WatchConnectivity")
                
            @unknown default:
                self.connectionState = .error("Unknown activation state")
                AppLogger.error("[WatchConnectivityManager] Unknown session activation state", category: "WatchConnectivity")
            }
            
            if let error = error {
                self.connectionState = .error(error.localizedDescription)
                AppLogger.error("[WatchConnectivityManager] Session activation error: \(error.localizedDescription)", category: "WatchConnectivity")
            }
        }
    }
    #endif
    
    #if os(watchOS)
    nonisolated public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        let isReachable = session.isReachable
        
        Task { @MainActor in
            switch activationState {
            case .activated:
                self.connectionState = .connected
                self.isReachable = isReachable
                self.processPendingMessages()
                AppLogger.info("[WatchConnectivityManager] Session activated successfully", category: "WatchConnectivity")
                
            case .inactive:
                self.connectionState = .disconnected
                AppLogger.warning("[WatchConnectivityManager] Session activated but is inactive", category: "WatchConnectivity")
                
            case .notActivated:
                self.connectionState = .error("Session not activated")
                AppLogger.error("[WatchConnectivityManager] Session activation failed", category: "WatchConnectivity")
                
            @unknown default:
                self.connectionState = .error("Unknown activation state")
                AppLogger.error("[WatchConnectivityManager] Unknown session activation state", category: "WatchConnectivity")
            }
            
            if let error = error {
                self.connectionState = .error(error.localizedDescription)
                AppLogger.error("[WatchConnectivityManager] Session activation error: \(error.localizedDescription)", category: "WatchConnectivity")
            }
        }
    }
    #endif
    
    nonisolated public func sessionReachabilityDidChange(_ session: WCSession) {
        let isReachable = session.isReachable
        
        Task { @MainActor in
            self.isReachable = isReachable
            if isReachable {
                self.connectionState = .connected
                self.processPendingMessages()
                AppLogger.info("[WatchConnectivityManager] Session became reachable", category: "WatchConnectivity")
            } else {
                self.connectionState = .disconnected
                AppLogger.warning("[WatchConnectivityManager] Session became unreachable", category: "WatchConnectivity")
            }
        }
    }
    
    nonisolated public func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        handleReceivedMessage(message, replyHandler: replyHandler)
    }
    
    nonisolated public func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        handleReceivedMessage(message, replyHandler: nil)
    }
    
    nonisolated private func handleReceivedMessage(_ message: [String: Any], replyHandler: (([String: Any]) -> Void)?) {
        guard let typeString = message["type"] as? String,
              let messageType = WatchMessage(rawValue: typeString) else {
            AppLogger.error("[WatchConnectivityManager] Received message with invalid or missing type", category: "WatchConnectivity")
            replyHandler?(["error": "Invalid message type"])
            return
        }
        
        let payload = message["payload"] as? Data
        
        Task { @MainActor in
            self.didReceiveMessage(messageType, payload: payload)
            AppLogger.debug("[WatchConnectivityManager] Received message: \(messageType.rawValue)", category: "WatchConnectivity")
        }
        
        replyHandler?(["status": "received"])
    }
    
    nonisolated public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        Task { @MainActor in
            self.didReceiveApplicationContextUpdate([:]) // TODO: Fix context passing for concurrency
            AppLogger.debug("[WatchConnectivityManager] Received application context update", category: "WatchConnectivity")
        }
    }
    
    #if os(iOS)
    nonisolated public func sessionDidBecomeInactive(_ session: WCSession) {
        Task { @MainActor in
            self.sessionDidBecomeInactive()
            AppLogger.info("[WatchConnectivityManager] Session became inactive", category: "WatchConnectivity")
        }
    }
    
    nonisolated public func sessionDidDeactivate(_ session: WCSession) {
        Task { @MainActor in
            self.sessionDidDeactivate()
            AppLogger.info("[WatchConnectivityManager] Session deactivated", category: "WatchConnectivity")
        }
        
        // Immediately reactivate the session on iOS
        session.activate()
    }
    
    nonisolated public func sessionWatchStateDidChange(_ session: WCSession) {
        let isWatchAppInstalled = session.isWatchAppInstalled
        Task { @MainActor in
            self.isWatchAppInstalled = isWatchAppInstalled
            self.sessionWatchStateDidChange()
            AppLogger.info("[WatchConnectivityManager] Watch state changed - App installed: \(isWatchAppInstalled)", category: "WatchConnectivity")
        }
    }
    #endif
}

// MARK: - WatchConnectivity Delegate Protocol
@MainActor
public protocol WatchConnectivityDelegate: AnyObject {
    func didReceiveMessage(_ message: WatchMessage, payload: Data?)
    func didReceiveApplicationContextUpdate(_ context: [String: Any])
    func sessionDidBecomeInactive()
    func sessionDidDeactivate()
    func sessionWatchStateDidChange()
}

// MARK: - Default implementations
public extension WatchConnectivityDelegate {
    func didReceiveApplicationContextUpdate(_ context: [String: Any]) {}
    func sessionDidBecomeInactive() {}
    func sessionDidDeactivate() {}
    func sessionWatchStateDidChange() {}
}

// MARK: - Errors
public enum WatchConnectivityError: LocalizedError {
    case sessionNotAvailable
    case sessionNotReachable
    case encodingFailed
    case decodingFailed
    
    public var errorDescription: String? {
        switch self {
        case .sessionNotAvailable:
            return "WatchConnectivity session is not available"
        case .sessionNotReachable:
            return "Watch is not reachable"
        case .encodingFailed:
            return "Failed to encode message payload"
        case .decodingFailed:
            return "Failed to decode message payload"
        }
    }
}