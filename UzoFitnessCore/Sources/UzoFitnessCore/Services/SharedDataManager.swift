import Foundation
import OSLog

// MARK: - Shared Data Keys
public enum SharedDataKey: String, CaseIterable {
    case currentWorkoutSession = "currentWorkoutSession"
    case currentExerciseIndex = "currentExerciseIndex"
    case timerState = "timerState"
    case workoutProgress = "workoutProgress"
    case lastSyncTimestamp = "lastSyncTimestamp"
    case pendingSetCompletions = "pendingSetCompletions"
    case workoutStarted = "workoutStarted"
}

// MARK: - Shared Data Objects
public struct SharedWorkoutSession: Codable {
    public let id: UUID
    public let title: String
    public let startTime: Date
    public let duration: TimeInterval?
    public let currentExerciseIndex: Int
    public let totalExercises: Int
    
    public init(id: UUID, title: String, startTime: Date, duration: TimeInterval?, currentExerciseIndex: Int, totalExercises: Int) {
        self.id = id
        self.title = title
        self.startTime = startTime
        self.duration = duration
        self.currentExerciseIndex = currentExerciseIndex
        self.totalExercises = totalExercises
    }
}

public struct SharedTimerState: Codable {
    public let isRunning: Bool
    public let duration: TimeInterval
    public let startTime: Date?
    public let exerciseName: String?
    
    public init(isRunning: Bool, duration: TimeInterval, startTime: Date?, exerciseName: String?) {
        self.isRunning = isRunning
        self.duration = duration
        self.startTime = startTime
        self.exerciseName = exerciseName
    }
}

public struct SharedWorkoutProgress: Codable {
    public let sessionId: UUID
    public let completedSets: Int
    public let totalSets: Int
    public let completedExercises: Int
    public let totalExercises: Int
    public let estimatedTimeRemaining: TimeInterval?
    
    public init(sessionId: UUID, completedSets: Int, totalSets: Int, completedExercises: Int, totalExercises: Int, estimatedTimeRemaining: TimeInterval?) {
        self.sessionId = sessionId
        self.completedSets = completedSets
        self.totalSets = totalSets
        self.completedExercises = completedExercises
        self.totalExercises = totalExercises
        self.estimatedTimeRemaining = estimatedTimeRemaining
    }
}

public struct PendingSetCompletion: Codable {
    public let id: UUID
    public let setId: UUID
    public let sessionExerciseId: UUID
    public let reps: Int
    public let weight: Double
    public let timestamp: Date
    
    public init(id: UUID = UUID(), setId: UUID, sessionExerciseId: UUID, reps: Int, weight: Double, timestamp: Date = Date()) {
        self.id = id
        self.setId = setId
        self.sessionExerciseId = sessionExerciseId
        self.reps = reps
        self.weight = weight
        self.timestamp = timestamp
    }
}

// MARK: - Shared Data Manager Protocol
public protocol SharedDataProtocol: AnyObject {
    func store<T: Codable>(_ object: T, forKey key: SharedDataKey) throws
    func retrieve<T: Codable>(_ type: T.Type, forKey key: SharedDataKey) -> T?
    func remove(forKey key: SharedDataKey)
    func removeAll()
    func synchronize() -> Bool
    
    // Convenience methods for common operations
    func storeCurrentWorkoutSession(_ session: SharedWorkoutSession) throws
    func getCurrentWorkoutSession() -> SharedWorkoutSession?
    func storeTimerState(_ timerState: SharedTimerState) throws
    func getTimerState() -> SharedTimerState?
    func storeWorkoutProgress(_ progress: SharedWorkoutProgress) throws
    func getWorkoutProgress() -> SharedWorkoutProgress?
    func addPendingSetCompletion(_ completion: PendingSetCompletion) throws
    func getPendingSetCompletions() -> [PendingSetCompletion]
    func removePendingSetCompletion(withId id: UUID)
    func updateLastSyncTimestamp()
    func getLastSyncTimestamp() -> Date?
}

// MARK: - Shared Data Manager Implementation
public final class SharedDataManager: SharedDataProtocol, @unchecked Sendable {
    
    public static let shared = SharedDataManager()
    
    private let appGroupIdentifier = "group.com.kosiuzodinma.UzoFitness"
    private let userDefaults: UserDefaults
    private let fileManager = FileManager.default
    private lazy var documentsDirectory: URL? = {
        return fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)?
            .appendingPathComponent("Documents")
    }()
    
    private init() {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            fatalError("Failed to initialize UserDefaults with App Group identifier: \(appGroupIdentifier)")
        }
        self.userDefaults = userDefaults
        createDocumentsDirectoryIfNeeded()
        AppLogger.info("[SharedDataManager] Initialized with App Group: \(appGroupIdentifier)", category: "SharedData")
    }
    
    private func createDocumentsDirectoryIfNeeded() {
        guard let documentsDirectory = documentsDirectory else {
            AppLogger.error("[SharedDataManager] Failed to get documents directory for App Group", category: "SharedData")
            return
        }
        
        if !fileManager.fileExists(atPath: documentsDirectory.path) {
            do {
                try fileManager.createDirectory(at: documentsDirectory, withIntermediateDirectories: true, attributes: nil)
                AppLogger.info("[SharedDataManager] Created documents directory at: \(documentsDirectory.path)", category: "SharedData")
            } catch {
                AppLogger.error("[SharedDataManager] Failed to create documents directory: \(error.localizedDescription)", category: "SharedData")
            }
        }
    }
    
    // MARK: - Core Storage Methods
    public func store<T: Codable>(_ object: T, forKey key: SharedDataKey) throws {
        do {
            let data = try JSONEncoder().encode(object)
            userDefaults.set(data, forKey: key.rawValue)
            
            AppLogger.debug("[SharedDataManager] Stored object for key: \(key.rawValue)", category: "SharedData")
        } catch {
            AppLogger.error("[SharedDataManager] Failed to encode object for key \(key.rawValue): \(error.localizedDescription)", category: "SharedData")
            throw SharedDataError.encodingFailed(error)
        }
    }
    
    public func retrieve<T: Codable>(_ type: T.Type, forKey key: SharedDataKey) -> T? {
        guard let data = userDefaults.data(forKey: key.rawValue) else {
            AppLogger.debug("[SharedDataManager] No data found for key: \(key.rawValue)", category: "SharedData")
            return nil
        }
        
        do {
            let object = try JSONDecoder().decode(type, from: data)
            AppLogger.debug("[SharedDataManager] Retrieved object for key: \(key.rawValue)", category: "SharedData")
            return object
        } catch {
            AppLogger.error("[SharedDataManager] Failed to decode object for key \(key.rawValue): \(error.localizedDescription)", category: "SharedData")
            return nil
        }
    }
    
    public func remove(forKey key: SharedDataKey) {
        userDefaults.removeObject(forKey: key.rawValue)
        AppLogger.debug("[SharedDataManager] Removed object for key: \(key.rawValue)", category: "SharedData")
    }
    
    public func removeAll() {
        for key in SharedDataKey.allCases {
            userDefaults.removeObject(forKey: key.rawValue)
        }
        AppLogger.info("[SharedDataManager] Removed all shared data", category: "SharedData")
    }
    
    public func synchronize() -> Bool {
        let success = userDefaults.synchronize()
        if success {
            AppLogger.debug("[SharedDataManager] Successfully synchronized UserDefaults", category: "SharedData")
        } else {
            AppLogger.warning("[SharedDataManager] Failed to synchronize UserDefaults", category: "SharedData")
        }
        return success
    }
    
    // MARK: - Convenience Methods
    public func storeCurrentWorkoutSession(_ session: SharedWorkoutSession) throws {
        try store(session, forKey: .currentWorkoutSession)
        updateLastSyncTimestamp()
    }
    
    public func getCurrentWorkoutSession() -> SharedWorkoutSession? {
        return retrieve(SharedWorkoutSession.self, forKey: .currentWorkoutSession)
    }
    
    public func storeTimerState(_ timerState: SharedTimerState) throws {
        try store(timerState, forKey: .timerState)
        updateLastSyncTimestamp()
    }
    
    public func getTimerState() -> SharedTimerState? {
        return retrieve(SharedTimerState.self, forKey: .timerState)
    }
    
    public func storeWorkoutProgress(_ progress: SharedWorkoutProgress) throws {
        try store(progress, forKey: .workoutProgress)
        updateLastSyncTimestamp()
    }
    
    public func getWorkoutProgress() -> SharedWorkoutProgress? {
        return retrieve(SharedWorkoutProgress.self, forKey: .workoutProgress)
    }
    
    public func addPendingSetCompletion(_ completion: PendingSetCompletion) throws {
        var pendingCompletions = getPendingSetCompletions()
        pendingCompletions.append(completion)
        try store(pendingCompletions, forKey: .pendingSetCompletions)
        updateLastSyncTimestamp()
        
        AppLogger.info("[SharedDataManager] Added pending set completion. Total pending: \(pendingCompletions.count)", category: "SharedData")
    }
    
    public func getPendingSetCompletions() -> [PendingSetCompletion] {
        return retrieve([PendingSetCompletion].self, forKey: .pendingSetCompletions) ?? []
    }
    
    public func removePendingSetCompletion(withId id: UUID) {
        var pendingCompletions = getPendingSetCompletions()
        pendingCompletions.removeAll { $0.id == id }
        
        do {
            try store(pendingCompletions, forKey: .pendingSetCompletions)
            updateLastSyncTimestamp()
            AppLogger.debug("[SharedDataManager] Removed pending set completion with id: \(id)", category: "SharedData")
        } catch {
            AppLogger.error("[SharedDataManager] Failed to remove pending set completion: \(error.localizedDescription)", category: "SharedData")
        }
    }
    
    public func updateLastSyncTimestamp() {
        userDefaults.set(Date().timeIntervalSince1970, forKey: SharedDataKey.lastSyncTimestamp.rawValue)
    }
    
    public func getLastSyncTimestamp() -> Date? {
        let timestamp = userDefaults.double(forKey: SharedDataKey.lastSyncTimestamp.rawValue)
        return timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : nil
    }
    
    // MARK: - File-based Storage (for larger data)
    public func storeToFile<T: Codable>(_ object: T, fileName: String) throws {
        guard let documentsDirectory = documentsDirectory else {
            throw SharedDataError.fileSystemError("Documents directory not available")
        }
        
        let fileURL = documentsDirectory.appendingPathComponent("\(fileName).json")
        let data = try JSONEncoder().encode(object)
        try data.write(to: fileURL)
        
        AppLogger.debug("[SharedDataManager] Stored object to file: \(fileName)", category: "SharedData")
    }
    
    public func retrieveFromFile<T: Codable>(_ type: T.Type, fileName: String) -> T? {
        guard let documentsDirectory = documentsDirectory else {
            AppLogger.error("[SharedDataManager] Documents directory not available for file: \(fileName)", category: "SharedData")
            return nil
        }
        
        let fileURL = documentsDirectory.appendingPathComponent("\(fileName).json")
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            AppLogger.debug("[SharedDataManager] File does not exist: \(fileName)", category: "SharedData")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let object = try JSONDecoder().decode(type, from: data)
            AppLogger.debug("[SharedDataManager] Retrieved object from file: \(fileName)", category: "SharedData")
            return object
        } catch {
            AppLogger.error("[SharedDataManager] Failed to retrieve object from file \(fileName): \(error.localizedDescription)", category: "SharedData")
            return nil
        }
    }
    
    public func removeFile(fileName: String) {
        guard let documentsDirectory = documentsDirectory else {
            AppLogger.error("[SharedDataManager] Documents directory not available for file removal: \(fileName)", category: "SharedData")
            return
        }
        
        let fileURL = documentsDirectory.appendingPathComponent("\(fileName).json")
        
        if fileManager.fileExists(atPath: fileURL.path) {
            do {
                try fileManager.removeItem(at: fileURL)
                AppLogger.debug("[SharedDataManager] Removed file: \(fileName)", category: "SharedData")
            } catch {
                AppLogger.error("[SharedDataManager] Failed to remove file \(fileName): \(error.localizedDescription)", category: "SharedData")
            }
        }
    }
}

// MARK: - Shared Data Errors
public enum SharedDataError: LocalizedError {
    case encodingFailed(Error)
    case decodingFailed(Error)
    case fileSystemError(String)
    case appGroupNotAvailable
    
    public var errorDescription: String? {
        switch self {
        case .encodingFailed(let error):
            return "Failed to encode data: \(error.localizedDescription)"
        case .decodingFailed(let error):
            return "Failed to decode data: \(error.localizedDescription)"
        case .fileSystemError(let message):
            return "File system error: \(message)"
        case .appGroupNotAvailable:
            return "App Group container is not available"
        }
    }
}