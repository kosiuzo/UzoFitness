import Foundation
import SwiftData
import Combine
import UIKit

// MARK: - App Settings Store
@MainActor
class AppSettingsStore: ObservableObject {
    @Published var lastBackupDate: Date?
    @Published var autoBackupEnabled: Bool = true
    @Published var lowBatteryThreshold: Double = 0.10 // 10%
    
    private let userDefaults = UserDefaults.standard
    
    init() {
        loadSettings()
        print("🔄 [AppSettingsStore.init] Initialized app settings store")
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
        print("✅ [AppSettingsStore.saveSettings] Settings saved to UserDefaults")
    }
    
    func updateLastBackupDate(_ date: Date) {
        lastBackupDate = date
        saveSettings()
        print("📊 [AppSettingsStore] Last backup date updated to: \(date)")
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
        print("🔄 [DefaultiCloudBackupService.performBackup] Starting backup")
        
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
        
        print("✅ [DefaultiCloudBackupService.performBackup] Backup completed successfully")
        return result
    }
    
    func performRestore() async throws -> RestoreResult {
        print("🔄 [DefaultiCloudBackupService.performRestore] Starting restore")
        
        // Simulate restore process
        try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
        
        let result = RestoreResult(
            success: true,
            itemsRestored: 148,
            duration: 3.0
        )
        
        print("✅ [DefaultiCloudBackupService.performRestore] Restore completed successfully")
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
        
        print("🔄 [SettingsViewModel.init] Initialized with dependencies")
        
        setupBindings()
        loadInitialState()
    }
    
    // MARK: - Intent Handling
    func handleIntent(_ intent: SettingsIntent) {
        print("🔄 [SettingsViewModel.handleIntent] Processing intent: \(intent)")
        
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
        
        print("✅ [SettingsViewModel.setupBindings] Bindings established")
    }
    
    private func loadInitialState() {
        print("🔄 [SettingsViewModel.loadInitialState] Loading initial permissions state")
        
        Task {
            await refreshPermissions()
        }
    }
    
    private func requestHealthKitAccess() async {
        print("🔄 [SettingsViewModel.requestHealthKitAccess] Requesting HealthKit authorization")
        state = .loading
        
        await withCheckedContinuation { continuation in
            healthKitManager.requestAuthorization { [weak self] success, error in
                Task { @MainActor in
                    if let error = error {
                        print("❌ [SettingsViewModel.requestHealthKitAccess] Error: \(error.localizedDescription)")
                        self?.error = error
                        self?.state = .error
                    } else {
                        print("✅ [SettingsViewModel.requestHealthKitAccess] Success: \(success)")
                        self?.isHealthKitEnabled = success
                        self?.state = success ? .loaded : .error
                        print("📊 [SettingsViewModel] HealthKit enabled state: \(success)")
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    private func togglePhotoAccess() async {
        print("🔄 [SettingsViewModel.togglePhotoAccess] Requesting photo library access")
        state = .loading
        
        let status = await photoService.requestPhotoLibraryAuthorization()
        let granted = status == .authorized || status == .limited
        
        isPhotoAccessGranted = granted
        state = .loaded
        
        print("✅ [SettingsViewModel.togglePhotoAccess] Photo access granted: \(granted)")
        print("📊 [SettingsViewModel] Photo access state: \(granted)")
    }
    
    private func performBackup() async {
        print("🔄 [SettingsViewModel.performBackup] Starting backup process")
        
        guard canPerformBackup else {
            let batteryError = SettingsError.lowBattery(current: batteryMonitor.batteryLevel)
            print("❌ [SettingsViewModel.performBackup] \(batteryError.localizedDescription)")
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
                
                print("✅ [SettingsViewModel.performBackup] Backup completed")
                print("📊 [SettingsViewModel] Backup result: \(result.itemCount) items, \(result.sizeInBytes) bytes")
            } else {
                throw SettingsError.backupFailed("Backup process failed")
            }
            
        } catch {
            print("❌ [SettingsViewModel.performBackup] Error: \(error.localizedDescription)")
            self.error = error
            backupProgress = 0.0
        }
        
        isLoadingBackup = false
    }
    
    private func performRestore() async {
        print("🔄 [SettingsViewModel.performRestore] Starting restore process")
        
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
                
                print("✅ [SettingsViewModel.performRestore] Restore completed")
                print("📊 [SettingsViewModel] Restore result: \(result.itemsRestored) items restored")
                
                // Refresh permissions after restore
                await refreshPermissions()
            } else {
                throw SettingsError.restoreFailed("Restore process failed")
            }
            
        } catch {
            print("❌ [SettingsViewModel.performRestore] Error: \(error.localizedDescription)")
            self.error = error
            restoreProgress = 0.0
        }
        
        isLoadingRestore = false
    }
    
    private func refreshPermissions() async {
        print("🔄 [SettingsViewModel.refreshPermissions] Refreshing permission states")
        
        // Check photo access
        let photoStatus = await photoService.requestPhotoLibraryAuthorization()
        isPhotoAccessGranted = photoStatus == .authorized || photoStatus == .limited
        
        // HealthKit permissions are harder to check directly, so we assume they're granted
        // if the user has previously authorized. In a real app, you might store this state.
        
        print("📊 [SettingsViewModel] Permissions refreshed - Photo: \(isPhotoAccessGranted)")
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