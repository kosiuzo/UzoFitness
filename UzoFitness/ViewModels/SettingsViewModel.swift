import Foundation
import SwiftData
import Combine
import UIKit
import UzoFitnessCore

// MARK: - App Settings Store
@MainActor
class AppSettingsStore: ObservableObject {
    @Published var lastBackupDate: Date?
    @Published var autoBackupEnabled: Bool = true
    @Published var lowBatteryThreshold: Double = 0.10 // 10%
    
    private let userDefaults = UserDefaults.standard
    
    init() {
        loadSettings()
        AppLogger.debug("[AppSettingsStore.init] Initialized app settings store", category: "AppSettingsStore")
    }
    
    private func loadSettings() {
        if let backupDate = userDefaults.object(forKey: "lastBackupDate") as? Date {
            lastBackupDate = backupDate
        }
        autoBackupEnabled = userDefaults.bool(forKey: "autoBackupEnabled")
        lowBatteryThreshold = userDefaults.double(forKey: "lowBatteryThreshold")
        
        // Set default threshold if not previously set
        if lowBatteryThreshold == 0 {
            lowBatteryThreshold = 0.10
            saveSettings()
        }
    }
    
    func saveSettings() {
        userDefaults.set(lastBackupDate, forKey: "lastBackupDate")
        userDefaults.set(autoBackupEnabled, forKey: "autoBackupEnabled")
        userDefaults.set(lowBatteryThreshold, forKey: "lowBatteryThreshold")
        AppLogger.info("[AppSettingsStore.saveSettings] Settings saved to UserDefaults", category: "AppSettingsStore")
    }
    
    func updateLastBackupDate(_ date: Date) {
        lastBackupDate = date
        saveSettings()
        AppLogger.debug("[AppSettingsStore] Last backup date updated to: \(date)", category: "AppSettingsStore")
    }
}

// MARK: - iCloud Backup Service Protocol
protocol iCloudBackupServiceProtocol {
    func performBackup() async throws -> BackupResult
    func performRestore() async throws -> RestoreResult
    func checkBackupAvailability() async -> Bool
    func getBackupSize() async throws -> Int64 // bytes
}

// MARK: - Battery Monitor Protocol
protocol BatteryMonitorProtocol {
    var batteryLevel: Float { get }
    var batteryState: UIDevice.BatteryState { get }
}

// MARK: - Default Implementations
class DefaultiCloudBackupService: iCloudBackupServiceProtocol {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func performBackup() async throws -> BackupResult {
        AppLogger.debug("[DefaultiCloudBackupService.performBackup] Starting backup", category: "iCloudBackupService")
        
        // Simulate backup process
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // In a real implementation, this would:
        // 1. Export SwiftData to CloudKit
        // 2. Upload progress photos to iCloud Drive
        // 3. Create manifest file
        
        let result = BackupResult(
            success: true,
            itemCount: 150,
            sizeInBytes: 1_024_000, // 1MB
            duration: 2.0
        )
        
        AppLogger.info("[DefaultiCloudBackupService.performBackup] Backup completed successfully", category: "iCloudBackupService")
        return result
    }
    
    func performRestore() async throws -> RestoreResult {
        AppLogger.debug("[DefaultiCloudBackupService.performRestore] Starting restore", category: "iCloudBackupService")
        
        // Simulate restore process
        try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
        
        let result = RestoreResult(
            success: true,
            itemsRestored: 148,
            duration: 3.0
        )
        
        AppLogger.info("[DefaultiCloudBackupService.performRestore] Restore completed successfully", category: "iCloudBackupService")
        return result
    }
    
    func checkBackupAvailability() async -> Bool {
        // In real implementation, check iCloud availability
        return true
    }
    
    func getBackupSize() async throws -> Int64 {
        // In real implementation, calculate actual size
        return 1_024_000 // 1MB
    }
}

class DefaultBatteryMonitor: BatteryMonitorProtocol {
    var batteryLevel: Float {
        UIDevice.current.batteryLevel
    }
    
    var batteryState: UIDevice.BatteryState {
        UIDevice.current.batteryState
    }
    
    init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
    }
}

// MARK: - Settings ViewModel
@MainActor
class SettingsViewModel: ObservableObject {
    // MARK: - Published State
    @Published var isHealthKitEnabled: Bool = false
    @Published var isPhotoAccessGranted: Bool = false
    @Published var lastBackupDate: Date?
    @Published var isLoadingBackup: Bool = false
    @Published var isLoadingRestore: Bool = false
    @Published var error: Error?
    @Published var state: SettingsLoadingState = .idle
    @Published var backupProgress: Double = 0.0
    @Published var restoreProgress: Double = 0.0
    
    // MARK: - Computed Properties
    var formattedLastBackupDate: String {
        guard let lastBackupDate = lastBackupDate else {
            return "Never"
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: lastBackupDate, relativeTo: Date())
    }
    
    var canPerformBackup: Bool {
        let batteryLevel = batteryMonitor.batteryLevel
        let isCharging = batteryMonitor.batteryState == .charging || batteryMonitor.batteryState == .full
        
        // Allow backup if charging or battery > threshold
        return isCharging || batteryLevel > Float(appSettingsStore.lowBatteryThreshold)
    }
    
    var backupStatusText: String {
        if isLoadingBackup {
            return "Backing up..."
        } else if isLoadingRestore {
            return "Restoring..."
        } else if !canPerformBackup {
            return "Low battery - plug in to backup"
        } else {
            return "Ready to backup"
        }
    }
    
    // MARK: - Private Properties
    private let healthKitManager: HealthKitManager
    private let photoService: PhotoService
    private let appSettingsStore: AppSettingsStore
    private let iCloudBackupService: iCloudBackupServiceProtocol
    private let batteryMonitor: BatteryMonitorProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(
        healthKitManager: HealthKitManager,
        photoService: PhotoService,
        appSettingsStore: AppSettingsStore,
        iCloudBackupService: iCloudBackupServiceProtocol? = nil,
        batteryMonitor: BatteryMonitorProtocol? = nil,
        modelContext: ModelContext
    ) {
        self.healthKitManager = healthKitManager
        self.photoService = photoService
        self.appSettingsStore = appSettingsStore
        self.iCloudBackupService = iCloudBackupService ?? DefaultiCloudBackupService(modelContext: modelContext)
        self.batteryMonitor = batteryMonitor ?? DefaultBatteryMonitor()
        
        AppLogger.debug("[SettingsViewModel.init] Initialized with dependencies", category: "SettingsViewModel")
        
        setupBindings()
        loadInitialState()
    }
    
    // MARK: - Intent Handling
    func handleIntent(_ intent: SettingsIntent) {
        AppLogger.debug("[SettingsViewModel.handleIntent] Processing intent: \(intent)", category: "SettingsViewModel")
        
        Task {
            switch intent {
            case .requestHealthKitAccess:
                await requestHealthKitAccess()
                
            case .togglePhotoAccess:
                await togglePhotoAccess()
                
            case .performBackup:
                await performBackup()
                
            case .performRestore:
                await performRestore()
                
            case .refreshPermissions:
                await refreshPermissions()
                
            case .clearError:
                error = nil
                
            case .loadInitialState:
                loadInitialState()
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Bind to app settings store
        appSettingsStore.$lastBackupDate
            .receive(on: DispatchQueue.main)
            .assign(to: \.lastBackupDate, on: self)
            .store(in: &cancellables)
        
        AppLogger.info("[SettingsViewModel.setupBindings] Bindings established", category: "SettingsViewModel")
    }
    
    private func loadInitialState() {
        AppLogger.debug("[SettingsViewModel.loadInitialState] Loading initial permissions state", category: "SettingsViewModel")
        
        Task {
            await refreshPermissions()
        }
    }
    
    private func requestHealthKitAccess() async {
        AppLogger.debug("[SettingsViewModel.requestHealthKitAccess] Requesting HealthKit authorization", category: "SettingsViewModel")
        state = .loading
        
        await withCheckedContinuation { continuation in
            healthKitManager.requestAuthorization { [weak self] success, error in
                Task { @MainActor in
                    if let error = error {
                        AppLogger.error("[SettingsViewModel.requestHealthKitAccess] Error: \(error.localizedDescription)", category: "SettingsViewModel", error: error)
                        self?.error = error
                        self?.state = .error
                    } else {
                        AppLogger.info("[SettingsViewModel.requestHealthKitAccess] Success: \(success)", category: "SettingsViewModel")
                        self?.isHealthKitEnabled = success
                        self?.state = success ? .loaded : .error
                        AppLogger.debug("[SettingsViewModel] HealthKit enabled state: \(success)", category: "SettingsViewModel")
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    private func togglePhotoAccess() async {
        AppLogger.debug("[SettingsViewModel.togglePhotoAccess] Requesting photo library access", category: "SettingsViewModel")
        state = .loading
        
        let status = await photoService.requestPhotoLibraryAuthorization()
        let granted = status == .authorized || status == .limited
        
        isPhotoAccessGranted = granted
        state = .loaded
        
        AppLogger.info("[SettingsViewModel.togglePhotoAccess] Photo access granted: \(granted)", category: "SettingsViewModel")
        AppLogger.debug("[SettingsViewModel] Photo access state: \(granted)", category: "SettingsViewModel")
    }
    
    private func performBackup() async {
        AppLogger.debug("[SettingsViewModel.performBackup] Starting backup process", category: "SettingsViewModel")
        
        guard canPerformBackup else {
            let batteryError = SettingsError.lowBattery(current: batteryMonitor.batteryLevel)
            AppLogger.error("[SettingsViewModel.performBackup] \(batteryError.localizedDescription)", category: "SettingsViewModel", error: batteryError)
            error = batteryError
            return
        }
        
        isLoadingBackup = true
        backupProgress = 0.0
        error = nil
        
        do {
            // Simulate progress updates
            let progressTask = Task {
                for progress in stride(from: 0.0, through: 1.0, by: 0.1) {
                    await MainActor.run {
                        backupProgress = progress
                    }
                    try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                }
            }
            
            let result = try await iCloudBackupService.performBackup()
            progressTask.cancel()
            
            if result.success {
                appSettingsStore.updateLastBackupDate(Date())
                backupProgress = 1.0
                
                AppLogger.info("[SettingsViewModel.performBackup] Backup completed", category: "SettingsViewModel")
                AppLogger.debug("[SettingsViewModel] Backup result: \(result.itemCount) items, \(result.sizeInBytes) bytes", category: "SettingsViewModel")
            } else {
                throw SettingsError.backupFailed("Backup process failed")
            }
            
        } catch {
            AppLogger.error("[SettingsViewModel.performBackup] Error: \(error.localizedDescription)", category: "SettingsViewModel", error: error)
            self.error = error
            backupProgress = 0.0
        }
        
        isLoadingBackup = false
    }
    
    private func performRestore() async {
        AppLogger.debug("[SettingsViewModel.performRestore] Starting restore process", category: "SettingsViewModel")
        
        isLoadingRestore = true
        restoreProgress = 0.0
        error = nil
        
        do {
            // Simulate progress updates
            let progressTask = Task {
                for progress in stride(from: 0.0, through: 1.0, by: 0.1) {
                    await MainActor.run {
                        restoreProgress = progress
                    }
                    try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                }
            }
            
            let result = try await iCloudBackupService.performRestore()
            progressTask.cancel()
            
            if result.success {
                restoreProgress = 1.0
                
                AppLogger.info("[SettingsViewModel.performRestore] Restore completed", category: "SettingsViewModel")
                AppLogger.debug("[SettingsViewModel] Restore result: \(result.itemsRestored) items restored", category: "SettingsViewModel")
                
                // Refresh permissions after restore
                await refreshPermissions()
            } else {
                throw SettingsError.restoreFailed("Restore process failed")
            }
            
        } catch {
            AppLogger.error("[SettingsViewModel.performRestore] Error: \(error.localizedDescription)", category: "SettingsViewModel", error: error)
            self.error = error
            restoreProgress = 0.0
        }
        
        isLoadingRestore = false
    }
    
    private func refreshPermissions() async {
        AppLogger.debug("[SettingsViewModel.refreshPermissions] Refreshing permission states", category: "SettingsViewModel")
        
        // Check photo access
        let photoStatus = await photoService.requestPhotoLibraryAuthorization()
        isPhotoAccessGranted = photoStatus == .authorized || photoStatus == .limited
        
        // HealthKit permissions are harder to check directly, so we assume they're granted
        // if the user has previously authorized. In a real app, you might store this state.
        
        AppLogger.debug("[SettingsViewModel] Permissions refreshed - Photo: \(isPhotoAccessGranted)", category: "SettingsViewModel")
    }
}

// MARK: - Supporting Types

enum SettingsIntent {
    case requestHealthKitAccess
    case togglePhotoAccess
    case performBackup
    case performRestore
    case refreshPermissions
    case clearError
    case loadInitialState
}

enum SettingsLoadingState {
    case idle
    case loading
    case loaded
    case error
}

enum SettingsError: Error, LocalizedError, Equatable {
    case lowBattery(current: Float)
    case backupFailed(String)
    case restoreFailed(String)
    case iCloudUnavailable
    case permissionDenied(String)
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .lowBattery(let current):
            return "Battery too low (\(Int(current * 100))%). Please charge your device before backing up."
        case .backupFailed(let message):
            return "Backup failed: \(message)"
        case .restoreFailed(let message):
            return "Restore failed: \(message)"
        case .iCloudUnavailable:
            return "iCloud is not available. Please check your internet connection and iCloud settings."
        case .permissionDenied(let service):
            return "Permission denied for \(service). Please check your privacy settings."
        case .networkError:
            return "Network error. Please check your internet connection."
        }
    }
}

// MARK: - Backup Result Types

struct BackupResult {
    let success: Bool
    let itemCount: Int
    let sizeInBytes: Int64
    let duration: TimeInterval
}

struct RestoreResult {
    let success: Bool
    let itemsRestored: Int
    let duration: TimeInterval
} 