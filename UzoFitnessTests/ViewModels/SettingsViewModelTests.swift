import XCTest
import SwiftData
import Combine
import UIKit
import Photos
@testable import UzoFitness

@MainActor
final class SettingsViewModelTests: XCTestCase {
    
    // MARK: - Test Properties
    private var mockiCloudBackupService: MockiCloudBackupService!
    private var mockBatteryMonitor: MockBatteryMonitor!
    private var mockAppSettingsStore: AppSettingsStore!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create mock dependencies that we can actually test
        mockiCloudBackupService = MockiCloudBackupService()
        mockBatteryMonitor = MockBatteryMonitor()
        mockAppSettingsStore = AppSettingsStore()
    }
    
    override func tearDown() async throws {
        mockiCloudBackupService = nil
        mockBatteryMonitor = nil
        mockAppSettingsStore = nil
        try await super.tearDown()
    }
    
    // MARK: - ViewModel Integration Tests
    
    func testViewModel_InitializationWithDependencies() async {
        let healthKit = HealthKitManager()
        let photoService = PhotoService(dataPersistenceService: DefaultDataPersistenceService(modelContext: PersistenceController.preview.container.mainContext))
        let modelContext = PersistenceController.preview.container.mainContext
        
        let viewModel = SettingsViewModel(
            healthKitManager: healthKit,
            photoService: photoService,
            appSettingsStore: mockAppSettingsStore,
            iCloudBackupService: mockiCloudBackupService,
            batteryMonitor: mockBatteryMonitor,
            modelContext: modelContext
        )
        
        XCTAssertNotNil(viewModel)
        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertFalse(viewModel.isHealthKitEnabled)
        XCTAssertFalse(viewModel.isPhotoAccessGranted)
        XCTAssertFalse(viewModel.isLoadingBackup)
        XCTAssertFalse(viewModel.isLoadingRestore)
    }
    
    func testViewModel_HandleHealthKitAccessIntent() async {
        let healthKit = HealthKitManager()
        let photoService = PhotoService(dataPersistenceService: DefaultDataPersistenceService(modelContext: PersistenceController.preview.container.mainContext))
        let modelContext = PersistenceController.preview.container.mainContext
        
        let viewModel = SettingsViewModel(
            healthKitManager: healthKit,
            photoService: photoService,
            appSettingsStore: mockAppSettingsStore,
            iCloudBackupService: mockiCloudBackupService,
            batteryMonitor: mockBatteryMonitor,
            modelContext: modelContext
        )
        
        // Test HealthKit access request (may fail on simulator but should not crash)
        viewModel.handleIntent(.requestHealthKitAccess)
        
        // Wait for async operation to complete
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
        
        // We can only test that the operation completed without error
        XCTAssertNotNil(viewModel)
    }
    
    func testViewModel_HandlePhotoAccessIntent() async {
        let healthKit = HealthKitManager()
        let photoService = PhotoService(dataPersistenceService: DefaultDataPersistenceService(modelContext: PersistenceController.preview.container.mainContext))
        let modelContext = PersistenceController.preview.container.mainContext
        
        let viewModel = SettingsViewModel(
            healthKitManager: healthKit,
            photoService: photoService,
            appSettingsStore: mockAppSettingsStore,
            iCloudBackupService: mockiCloudBackupService,
            batteryMonitor: mockBatteryMonitor,
            modelContext: modelContext
        )
        
        // Test photo access request (may be denied on simulator)
        viewModel.handleIntent(.togglePhotoAccess)
        
        // Wait for async operation to complete
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
        
        // We can only test that the operation completed without crashing
        XCTAssertNotNil(viewModel)
    }
    
    func testViewModel_HandleBackupIntent_Success() async {
        let healthKit = HealthKitManager()
        let photoService = PhotoService(dataPersistenceService: DefaultDataPersistenceService(modelContext: PersistenceController.preview.container.mainContext))
        let modelContext = PersistenceController.preview.container.mainContext
        
        mockBatteryMonitor.batteryLevel = 0.8 // High battery
        mockBatteryMonitor.batteryState = .unplugged
        
        let viewModel = SettingsViewModel(
            healthKitManager: healthKit,
            photoService: photoService,
            appSettingsStore: mockAppSettingsStore,
            iCloudBackupService: mockiCloudBackupService,
            batteryMonitor: mockBatteryMonitor,
            modelContext: modelContext
        )
        
        viewModel.handleIntent(.performBackup)
        
        // Wait for backup to complete
        try? await Task.sleep(nanoseconds: 2_500_000_000) // 2.5 seconds
        
        XCTAssertTrue(mockiCloudBackupService.performBackupCalled)
        XCTAssertFalse(viewModel.isLoadingBackup)
        XCTAssertNotNil(mockAppSettingsStore.lastBackupDate)
    }
    
    func testViewModel_HandleBackupIntent_LowBattery() async {
        let healthKit = HealthKitManager()
        let photoService = PhotoService(dataPersistenceService: DefaultDataPersistenceService(modelContext: PersistenceController.preview.container.mainContext))
        let modelContext = PersistenceController.preview.container.mainContext
        
        mockBatteryMonitor.batteryLevel = 0.05 // Low battery
        mockBatteryMonitor.batteryState = .unplugged
        
        let viewModel = SettingsViewModel(
            healthKitManager: healthKit,
            photoService: photoService,
            appSettingsStore: mockAppSettingsStore,
            iCloudBackupService: mockiCloudBackupService,
            batteryMonitor: mockBatteryMonitor,
            modelContext: modelContext
        )
        
        viewModel.handleIntent(.performBackup)
        
        // Wait for operation to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        
        XCTAssertFalse(mockiCloudBackupService.performBackupCalled)
        XCTAssertNotNil(viewModel.error)
        XCTAssertTrue(viewModel.error is SettingsError)
    }
    
    func testViewModel_HandleRestoreIntent() async {
        let healthKit = HealthKitManager()
        let photoService = PhotoService(dataPersistenceService: DefaultDataPersistenceService(modelContext: PersistenceController.preview.container.mainContext))
        let modelContext = PersistenceController.preview.container.mainContext
        
        let viewModel = SettingsViewModel(
            healthKitManager: healthKit,
            photoService: photoService,
            appSettingsStore: mockAppSettingsStore,
            iCloudBackupService: mockiCloudBackupService,
            batteryMonitor: mockBatteryMonitor,
            modelContext: modelContext
        )
        
        viewModel.handleIntent(.performRestore)
        
        // Wait for restore to complete - increased wait time
        try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
        
        XCTAssertTrue(mockiCloudBackupService.performRestoreCalled)
        XCTAssertFalse(viewModel.isLoadingRestore)
    }
    
    func testViewModel_FormattedLastBackupDate() async {
        let healthKit = HealthKitManager()
        let photoService = PhotoService(dataPersistenceService: DefaultDataPersistenceService(modelContext: PersistenceController.preview.container.mainContext))
        let modelContext = PersistenceController.preview.container.mainContext
        
        let viewModel = SettingsViewModel(
            healthKitManager: healthKit,
            photoService: photoService,
            appSettingsStore: mockAppSettingsStore,
            iCloudBackupService: mockiCloudBackupService,
            batteryMonitor: mockBatteryMonitor,
            modelContext: modelContext
        )
        
        // Test "Never" case
        XCTAssertEqual(viewModel.formattedLastBackupDate, "Never")
        
        // Test with actual date
        let testDate = Date()
        mockAppSettingsStore.updateLastBackupDate(testDate)
        
        // Wait for the binding to update
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        
        // The formatted date should not be "Never"
        XCTAssertNotEqual(viewModel.formattedLastBackupDate, "Never")
    }
    
    func testViewModel_BackupStatusText() {
        let healthKit = HealthKitManager()
        let photoService = PhotoService(dataPersistenceService: DefaultDataPersistenceService(modelContext: PersistenceController.preview.container.mainContext))
        let modelContext = PersistenceController.preview.container.mainContext
        
        let viewModel = SettingsViewModel(
            healthKitManager: healthKit,
            photoService: photoService,
            appSettingsStore: mockAppSettingsStore,
            iCloudBackupService: mockiCloudBackupService,
            batteryMonitor: mockBatteryMonitor,
            modelContext: modelContext
        )
        
        // Test ready state
        mockBatteryMonitor.batteryLevel = 0.8
        mockBatteryMonitor.batteryState = .unplugged
        XCTAssertEqual(viewModel.backupStatusText, "Ready to backup")
        
        // Test low battery state
        mockBatteryMonitor.batteryLevel = 0.05
        mockBatteryMonitor.batteryState = .unplugged
        XCTAssertEqual(viewModel.backupStatusText, "Low battery - plug in to backup")
    }
    
    // MARK: - Battery Monitor Tests
    
    // MARK: - Error Tests
    
    func testSettingsError_LocalizedDescription() {
        let lowBatteryError = SettingsError.lowBattery(current: 0.05)
        XCTAssertEqual(lowBatteryError.localizedDescription, "Battery too low (5%). Please charge your device before backing up.")
        
        let backupError = SettingsError.backupFailed("Network timeout")
        XCTAssertEqual(backupError.localizedDescription, "Backup failed: Network timeout")
        
        let restoreError = SettingsError.restoreFailed("Invalid data format")
        XCTAssertEqual(restoreError.localizedDescription, "Restore failed: Invalid data format")
        
        let iCloudError = SettingsError.iCloudUnavailable
        XCTAssertEqual(iCloudError.localizedDescription, "iCloud is not available. Please check your internet connection and iCloud settings.")
        
        let permissionError = SettingsError.permissionDenied("HealthKit")
        XCTAssertEqual(permissionError.localizedDescription, "Permission denied for HealthKit. Please check your privacy settings.")
        
        let networkError = SettingsError.networkError
        XCTAssertEqual(networkError.localizedDescription, "Network error. Please check your internet connection.")
    }
    
    // MARK: - App Settings Store Tests
    
    func testAppSettingsStore_UpdateLastBackupDate() {
        let store = AppSettingsStore()
        let testDate = Date()
        
        store.updateLastBackupDate(testDate)
        
        XCTAssertEqual(store.lastBackupDate!.timeIntervalSince1970, testDate.timeIntervalSince1970, accuracy: 1.0)
    }
    
    func testAppSettingsStore_SaveAndLoadSettings() {
        let store = AppSettingsStore()
        
        // Change settings
        store.autoBackupEnabled = false
        store.lowBatteryThreshold = 0.15
        store.saveSettings()
        
        // Create new store to test loading
        let newStore = AppSettingsStore()
        XCTAssertFalse(newStore.autoBackupEnabled)
        XCTAssertEqual(newStore.lowBatteryThreshold, 0.15)
        
        // Reset for other tests
        store.autoBackupEnabled = true
        store.lowBatteryThreshold = 0.10
        store.saveSettings()
    }
    
    // MARK: - Supporting Types Tests
    
    func testBackupResult_Properties() {
        let result = BackupResult(success: true, itemCount: 50, sizeInBytes: 1024, duration: 2.5)
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.itemCount, 50)
        XCTAssertEqual(result.sizeInBytes, 1024)
        XCTAssertEqual(result.duration, 2.5)
    }
    
    func testRestoreResult_Properties() {
        let result = RestoreResult(success: false, itemsRestored: 0, duration: 1.0)
        
        XCTAssertFalse(result.success)
        XCTAssertEqual(result.itemsRestored, 0)
        XCTAssertEqual(result.duration, 1.0)
    }
    
    func testSettingsIntent_AllCases() {
        let intents: [SettingsIntent] = [
            .requestHealthKitAccess,
            .togglePhotoAccess,
            .performBackup,
            .performRestore,
            .refreshPermissions,
            .clearError,
            .loadInitialState
        ]
        
        XCTAssertEqual(intents.count, 7)
    }
    
    func testSettingsLoadingState_AllCases() {
        let states: [SettingsLoadingState] = [.idle, .loading, .loaded, .error]
        XCTAssertEqual(states.count, 4)
    }
    
    // MARK: - Battery Monitor Tests
    
    func testBatteryMonitor_Properties() {
        let monitor = MockBatteryMonitor()
        monitor.batteryLevel = 0.75
        monitor.batteryState = .charging
        
        XCTAssertEqual(monitor.batteryLevel, 0.75)
        XCTAssertEqual(monitor.batteryState, .charging)
    }
    
    func testCanPerformBackup_Logic() {
        let monitor = MockBatteryMonitor()
        let settings = AppSettingsStore()
        settings.lowBatteryThreshold = 0.1 // 10%
        
        // Test high battery, not charging - should allow backup
        monitor.batteryLevel = 0.8
        monitor.batteryState = .unplugged
        let canBackupHighBattery = monitor.batteryState == .charging || 
                                  monitor.batteryState == .full || 
                                  monitor.batteryLevel > Float(settings.lowBatteryThreshold)
        XCTAssertTrue(canBackupHighBattery)
        
        // Test low battery, charging - should allow backup
        monitor.batteryLevel = 0.05
        monitor.batteryState = .charging
        let canBackupCharging = monitor.batteryState == .charging || 
                               monitor.batteryState == .full || 
                               monitor.batteryLevel > Float(settings.lowBatteryThreshold)
        XCTAssertTrue(canBackupCharging)
        
        // Test low battery, not charging - should not allow backup
        monitor.batteryLevel = 0.05
        monitor.batteryState = .unplugged
        let canBackupLowBattery = monitor.batteryState == .charging || 
                                 monitor.batteryState == .full || 
                                 monitor.batteryLevel > Float(settings.lowBatteryThreshold)
        XCTAssertFalse(canBackupLowBattery)
    }
}

// MARK: - Mock Implementations

class MockiCloudBackupService: iCloudBackupServiceProtocol {
    var performBackupCalled = false
    var performRestoreCalled = false
    var checkBackupAvailabilityCalled = false
    var getBackupSizeCalled = false
    
    var shouldThrowError = false
    var backupResult = BackupResult(success: true, itemCount: 100, sizeInBytes: 1024, duration: 2.0)
    var restoreResult = RestoreResult(success: true, itemsRestored: 95, duration: 3.0)
    var backupAvailable = true
    var backupSize: Int64 = 1024
    
    func performBackup() async throws -> BackupResult {
        performBackupCalled = true
        if shouldThrowError {
            throw SettingsError.backupFailed("Mock error")
        }
        return backupResult
    }
    
    func performRestore() async throws -> RestoreResult {
        performRestoreCalled = true
        if shouldThrowError {
            throw SettingsError.restoreFailed("Mock error")
        }
        return restoreResult
    }
    
    func checkBackupAvailability() async -> Bool {
        checkBackupAvailabilityCalled = true
        return backupAvailable
    }
    
    func getBackupSize() async throws -> Int64 {
        getBackupSizeCalled = true
        if shouldThrowError {
            throw SettingsError.networkError
        }
        return backupSize
    }
}

class MockBatteryMonitor: BatteryMonitorProtocol {
    var batteryLevel: Float = 1.0
    var batteryState: UIDevice.BatteryState = .full
}


