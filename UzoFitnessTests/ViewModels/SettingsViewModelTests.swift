import XCTest
import SwiftData
import UIKit
import UzoFitnessCore
@testable import UzoFitness

@MainActor
class SettingsViewModelTests: XCTestCase {
    
    // MARK: - Test Properties
    private var persistenceController: InMemoryPersistenceController!
    private var viewModel: SettingsViewModel!
    private var mockHealthKitManager: HealthKitManager!
    private var mockPhotoService: PhotoService!
    private var mockAppSettingsStore: AppSettingsStore!
    
    // MARK: - Setup and Teardown
    
    override func setUp() {
        super.setUp()
        
        // Create in-memory persistence controller
        persistenceController = InMemoryPersistenceController()
        
        // Create mock services
        mockHealthKitManager = HealthKitManager(
            healthStore: MockHealthStore(),
            calendar: CalendarWrapper(Calendar.current),
            typeFactory: HealthKitTypeFactory(),
            queryExecutor: MockQueryExecutor()
        )
        
        mockPhotoService = PhotoService(
            fileSystemService: MockFileSystemService(),
            imagePickerService: MockImagePickerService(),
            dataPersistenceService: DefaultDataPersistenceService(modelContext: persistenceController.context)
        )
        
        mockAppSettingsStore = AppSettingsStore()
        
        // Create view model with test dependencies
        viewModel = SettingsViewModel(
            healthKitManager: mockHealthKitManager,
            photoService: mockPhotoService,
            appSettingsStore: mockAppSettingsStore,
            modelContext: persistenceController.context
        )
    }
    
    override func tearDown() {
        // Clean up test data
        persistenceController.cleanupTestData()
        viewModel = nil
        mockHealthKitManager = nil
        mockPhotoService = nil
        mockAppSettingsStore = nil
        persistenceController = nil
        
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization_DefaultState() {
        // Given: A newly initialized SettingsViewModel
        // (viewModel created in setUp)
        
        // Then: Should have correct default state
        XCTAssertFalse(viewModel.isHealthKitEnabled, "HealthKit should be disabled initially")
        XCTAssertFalse(viewModel.isPhotoAccessGranted, "Photo access should be denied initially")
        XCTAssertNil(viewModel.lastBackupDate, "Last backup date should be nil initially")
        XCTAssertFalse(viewModel.isLoadingBackup, "Should not be loading backup initially")
        XCTAssertFalse(viewModel.isLoadingRestore, "Should not be loading restore initially")
        XCTAssertNil(viewModel.error, "Should have no error initially")
        XCTAssertEqual(viewModel.state, .idle, "State should be idle initially")
        XCTAssertEqual(viewModel.backupProgress, 0.0, "Backup progress should be 0 initially")
        XCTAssertEqual(viewModel.restoreProgress, 0.0, "Restore progress should be 0 initially")
    }
    
    func testInitialization_DependencyInjection() {
        // Given: Custom dependencies
        let customPersistenceController = InMemoryPersistenceController()
        let customHealthKitManager = HealthKitManager(
            healthStore: MockHealthStore(),
            calendar: CalendarWrapper(Calendar.current),
            typeFactory: HealthKitTypeFactory(),
            queryExecutor: MockQueryExecutor()
        )
        let customPhotoService = PhotoService(
            fileSystemService: MockFileSystemService(),
            imagePickerService: MockImagePickerService(),
            dataPersistenceService: DefaultDataPersistenceService(modelContext: customPersistenceController.context)
        )
        let customAppSettingsStore = AppSettingsStore()
        
        // When: Creating a view model with custom dependencies
        let customViewModel = SettingsViewModel(
            healthKitManager: customHealthKitManager,
            photoService: customPhotoService,
            appSettingsStore: customAppSettingsStore,
            modelContext: customPersistenceController.context
        )
        
        // Then: The view model should be created successfully
        XCTAssertNotNil(customViewModel, "View model should be created successfully")
        XCTAssertEqual(customViewModel.state, .idle, "Should start with idle state")
        XCTAssertNil(customViewModel.error, "No error should occur with valid dependencies")
        
        // Clean up
        customPersistenceController.cleanupTestData()
    }
    
    // MARK: - Computed Properties Tests
    
    
    func testComputedProperties_BackupStatusText() {
        // Given: A SettingsViewModel in different states
        // (viewModel created in setUp)
        
        // When: Getting backup status text in idle state
        let idleStatus = viewModel.backupStatusText
        
        // Then: Should indicate ready state or battery status
        XCTAssertTrue(idleStatus == "Ready to backup" || idleStatus.contains("battery"), "Should show appropriate status")
        
        // When: Setting loading backup state
        viewModel.isLoadingBackup = true
        let loadingBackupStatus = viewModel.backupStatusText
        
        // Then: Should show backing up status
        XCTAssertEqual(loadingBackupStatus, "Backing up...", "Should show backing up status")
        
        // When: Setting loading restore state
        viewModel.isLoadingBackup = false
        viewModel.isLoadingRestore = true
        let loadingRestoreStatus = viewModel.backupStatusText
        
        // Then: Should show restoring status
        XCTAssertEqual(loadingRestoreStatus, "Restoring...", "Should show restoring status")
    }
    
    // MARK: - App Settings Store Tests
    
    
    func testAppSettingsStore_UpdateLastBackupDate() {
        // Given: An AppSettingsStore
        let settingsStore = AppSettingsStore()
        let testDate = Date()
        
        // When: Updating the last backup date
        settingsStore.updateLastBackupDate(testDate)
        
        // Then: The date should be updated
        XCTAssertEqual(settingsStore.lastBackupDate, testDate, "Last backup date should be updated")
    }
    
    // MARK: - State Management Tests
    
    func testStateManagement_InitialState() {
        // Given: A newly initialized SettingsViewModel
        // (viewModel created in setUp)
        
        // Then: Should be in idle state
        XCTAssertEqual(viewModel.state, .idle, "Initial state should be idle")
        XCTAssertNil(viewModel.error, "Should have no error initially")
    }
    
    func testStateManagement_ErrorClearing() {
        // Given: A SettingsViewModel with an error
        let testError = SettingsError.networkError
        viewModel.error = testError
        
        // When: Clearing the error
        viewModel.error = nil
        
        // Then: Error should be cleared
        XCTAssertNil(viewModel.error, "Error should be cleared")
    }
    
    func testStateManagement_LoadingStates() {
        // Given: A SettingsViewModel in default state
        // (viewModel created in setUp)
        
        // When: Setting loading states
        viewModel.isLoadingBackup = true
        viewModel.isLoadingRestore = false
        
        // Then: Loading states should be updated
        XCTAssertTrue(viewModel.isLoadingBackup, "Backup loading should be true")
        XCTAssertFalse(viewModel.isLoadingRestore, "Restore loading should be false")
        
        // When: Switching loading states
        viewModel.isLoadingBackup = false
        viewModel.isLoadingRestore = true
        
        // Then: Loading states should be switched
        XCTAssertFalse(viewModel.isLoadingBackup, "Backup loading should be false")
        XCTAssertTrue(viewModel.isLoadingRestore, "Restore loading should be true")
    }
    
    func testStateManagement_ProgressValues() {
        // Given: A SettingsViewModel with default progress
        // (viewModel created in setUp)
        
        // When: Setting progress values
        viewModel.backupProgress = 0.5
        viewModel.restoreProgress = 0.8
        
        // Then: Progress values should be updated
        XCTAssertEqual(viewModel.backupProgress, 0.5, "Backup progress should be 0.5")
        XCTAssertEqual(viewModel.restoreProgress, 0.8, "Restore progress should be 0.8")
        
        // When: Resetting progress values
        viewModel.backupProgress = 0.0
        viewModel.restoreProgress = 0.0
        
        // Then: Progress values should be reset
        XCTAssertEqual(viewModel.backupProgress, 0.0, "Backup progress should be reset to 0.0")
        XCTAssertEqual(viewModel.restoreProgress, 0.0, "Restore progress should be reset to 0.0")
    }
    
    // MARK: - Permission States Tests
    
    func testPermissionStates_InitialValues() {
        // Given: A newly initialized SettingsViewModel
        // (viewModel created in setUp)
        
        // Then: Permission states should be false initially
        XCTAssertFalse(viewModel.isHealthKitEnabled, "HealthKit should be disabled initially")
        XCTAssertFalse(viewModel.isPhotoAccessGranted, "Photo access should be denied initially")
    }
    
    func testPermissionStates_ManualUpdates() {
        // Given: A SettingsViewModel with default permission states
        // (viewModel created in setUp)
        
        // When: Manually updating permission states
        viewModel.isHealthKitEnabled = true
        viewModel.isPhotoAccessGranted = true
        
        // Then: Permission states should be updated
        XCTAssertTrue(viewModel.isHealthKitEnabled, "HealthKit should be enabled")
        XCTAssertTrue(viewModel.isPhotoAccessGranted, "Photo access should be granted")
        
        // When: Disabling permissions
        viewModel.isHealthKitEnabled = false
        viewModel.isPhotoAccessGranted = false
        
        // Then: Permission states should be disabled
        XCTAssertFalse(viewModel.isHealthKitEnabled, "HealthKit should be disabled")
        XCTAssertFalse(viewModel.isPhotoAccessGranted, "Photo access should be denied")
    }
    
    // MARK: - Permission Tests
    
    func testPermissions_HealthKitPermissionState() {
        // Given: A SettingsViewModel with default HealthKit permission
        // (viewModel created in setUp)
        
        // Then: HealthKit should be disabled initially
        XCTAssertFalse(viewModel.isHealthKitEnabled, "HealthKit should be disabled initially")
        
        // When: Manually enabling HealthKit permission
        viewModel.isHealthKitEnabled = true
        
        // Then: HealthKit should be enabled
        XCTAssertTrue(viewModel.isHealthKitEnabled, "HealthKit should be enabled after manual update")
        
        // When: Disabling HealthKit permission
        viewModel.isHealthKitEnabled = false
        
        // Then: HealthKit should be disabled
        XCTAssertFalse(viewModel.isHealthKitEnabled, "HealthKit should be disabled after manual update")
    }
    
    func testPermissions_PhotoAccessPermissionState() {
        // Given: A SettingsViewModel with default photo access permission
        // (viewModel created in setUp)
        
        // Then: Photo access should be denied initially
        XCTAssertFalse(viewModel.isPhotoAccessGranted, "Photo access should be denied initially")
        
        // When: Manually granting photo access
        viewModel.isPhotoAccessGranted = true
        
        // Then: Photo access should be granted
        XCTAssertTrue(viewModel.isPhotoAccessGranted, "Photo access should be granted after manual update")
        
        // When: Denying photo access
        viewModel.isPhotoAccessGranted = false
        
        // Then: Photo access should be denied
        XCTAssertFalse(viewModel.isPhotoAccessGranted, "Photo access should be denied after manual update")
    }
    
    func testPermissions_BothPermissionsState() {
        // Given: A SettingsViewModel with default permissions
        // (viewModel created in setUp)
        
        // When: Enabling both permissions
        viewModel.isHealthKitEnabled = true
        viewModel.isPhotoAccessGranted = true
        
        // Then: Both permissions should be enabled
        XCTAssertTrue(viewModel.isHealthKitEnabled, "HealthKit should be enabled")
        XCTAssertTrue(viewModel.isPhotoAccessGranted, "Photo access should be granted")
        
        // When: Disabling both permissions
        viewModel.isHealthKitEnabled = false
        viewModel.isPhotoAccessGranted = false
        
        // Then: Both permissions should be disabled
        XCTAssertFalse(viewModel.isHealthKitEnabled, "HealthKit should be disabled")
        XCTAssertFalse(viewModel.isPhotoAccessGranted, "Photo access should be denied")
    }
    
    func testPermissions_StateIndependence() {
        // Given: A SettingsViewModel with default permissions
        // (viewModel created in setUp)
        
        // When: Enabling only HealthKit
        viewModel.isHealthKitEnabled = true
        viewModel.isPhotoAccessGranted = false
        
        // Then: Only HealthKit should be enabled
        XCTAssertTrue(viewModel.isHealthKitEnabled, "HealthKit should be enabled")
        XCTAssertFalse(viewModel.isPhotoAccessGranted, "Photo access should remain denied")
        
        // When: Enabling only photo access
        viewModel.isHealthKitEnabled = false
        viewModel.isPhotoAccessGranted = true
        
        // Then: Only photo access should be granted
        XCTAssertFalse(viewModel.isHealthKitEnabled, "HealthKit should be disabled")
        XCTAssertTrue(viewModel.isPhotoAccessGranted, "Photo access should be granted")
    }
    
    // MARK: - Backup Tests
    
    func testBackup_InitialBackupState() {
        // Given: A SettingsViewModel with default backup state
        // (viewModel created in setUp)
        
        // Then: Backup should not be in progress initially
        XCTAssertFalse(viewModel.isLoadingBackup, "Should not be loading backup initially")
        XCTAssertEqual(viewModel.backupProgress, 0.0, "Backup progress should be 0 initially")
        XCTAssertNil(viewModel.lastBackupDate, "Last backup date should be nil initially")
    }
    
    func testBackup_LoadingBackupState() {
        // Given: A SettingsViewModel in default state
        // (viewModel created in setUp)
        
        // When: Starting backup loading
        viewModel.isLoadingBackup = true
        viewModel.backupProgress = 0.5
        
        // Then: Backup loading state should be updated
        XCTAssertTrue(viewModel.isLoadingBackup, "Should be loading backup")
        XCTAssertEqual(viewModel.backupProgress, 0.5, "Backup progress should be 0.5")
        
        // When: Completing backup loading
        viewModel.isLoadingBackup = false
        viewModel.backupProgress = 1.0
        
        // Then: Backup should be completed
        XCTAssertFalse(viewModel.isLoadingBackup, "Should not be loading backup")
        XCTAssertEqual(viewModel.backupProgress, 1.0, "Backup progress should be 1.0")
    }
    
    func testBackup_RestoreState() {
        // Given: A SettingsViewModel in default state
        // (viewModel created in setUp)
        
        // When: Starting restore loading
        viewModel.isLoadingRestore = true
        viewModel.restoreProgress = 0.3
        
        // Then: Restore loading state should be updated
        XCTAssertTrue(viewModel.isLoadingRestore, "Should be loading restore")
        XCTAssertEqual(viewModel.restoreProgress, 0.3, "Restore progress should be 0.3")
        
        // When: Completing restore loading
        viewModel.isLoadingRestore = false
        viewModel.restoreProgress = 1.0
        
        // Then: Restore should be completed
        XCTAssertFalse(viewModel.isLoadingRestore, "Should not be loading restore")
        XCTAssertEqual(viewModel.restoreProgress, 1.0, "Restore progress should be 1.0")
    }
    
    func testBackup_ProgressReset() {
        // Given: A SettingsViewModel with some progress
        viewModel.backupProgress = 0.7
        viewModel.restoreProgress = 0.4
        
        // When: Resetting progress
        viewModel.backupProgress = 0.0
        viewModel.restoreProgress = 0.0
        
        // Then: Progress should be reset
        XCTAssertEqual(viewModel.backupProgress, 0.0, "Backup progress should be reset")
        XCTAssertEqual(viewModel.restoreProgress, 0.0, "Restore progress should be reset")
    }
    
    func testBackup_LastBackupDate() {
        // Given: A SettingsViewModel with no backup date
        // (viewModel created in setUp)
        
        // When: Setting a last backup date
        let testDate = Date()
        viewModel.lastBackupDate = testDate
        
        // Then: Last backup date should be updated
        XCTAssertEqual(viewModel.lastBackupDate, testDate, "Last backup date should be updated")
        
        // When: Clearing the backup date
        viewModel.lastBackupDate = nil
        
        // Then: Last backup date should be nil
        XCTAssertNil(viewModel.lastBackupDate, "Last backup date should be nil")
    }
    
    func testBackup_BatteryProtection() {
        // Given: A SettingsViewModel with battery protection logic
        // (viewModel created in setUp)
        
        // When: Getting backup status text
        let statusText = viewModel.backupStatusText
        
        // Then: Should return appropriate status
        XCTAssertTrue(
            statusText == "Ready to backup" || statusText.contains("battery") || statusText.contains("Backing up") || statusText.contains("Restoring"),
            "Should return appropriate backup status"
        )
    }
    
    func testBackup_ErrorHandling() {
        // Given: A SettingsViewModel with no error
        // (viewModel created in setUp)
        
        // When: Setting a backup error
        let testError = SettingsError.backupFailed("Test backup failure")
        viewModel.error = testError
        
        // Then: Error should be set
        XCTAssertNotNil(viewModel.error, "Error should be set")
        XCTAssertEqual(viewModel.error as? SettingsError, testError, "Error should match test error")
        
        // When: Clearing the error
        viewModel.error = nil
        
        // Then: Error should be cleared
        XCTAssertNil(viewModel.error, "Error should be cleared")
    }
    
    func testBackup_ConcurrentOperations() {
        // Given: A SettingsViewModel in default state
        // (viewModel created in setUp)
        
        // When: Setting both backup and restore loading simultaneously
        viewModel.isLoadingBackup = true
        viewModel.isLoadingRestore = true
        viewModel.backupProgress = 0.6
        viewModel.restoreProgress = 0.8
        
        // Then: Both operations should be in progress
        XCTAssertTrue(viewModel.isLoadingBackup, "Backup should be loading")
        XCTAssertTrue(viewModel.isLoadingRestore, "Restore should be loading")
        XCTAssertEqual(viewModel.backupProgress, 0.6, "Backup progress should be 0.6")
        XCTAssertEqual(viewModel.restoreProgress, 0.8, "Restore progress should be 0.8")
        
        // When: Stopping backup but continuing restore
        viewModel.isLoadingBackup = false
        viewModel.backupProgress = 0.0
        
        // Then: Only restore should be in progress
        XCTAssertFalse(viewModel.isLoadingBackup, "Backup should not be loading")
        XCTAssertTrue(viewModel.isLoadingRestore, "Restore should still be loading")
        XCTAssertEqual(viewModel.backupProgress, 0.0, "Backup progress should be reset")
        XCTAssertEqual(viewModel.restoreProgress, 0.8, "Restore progress should remain unchanged")
    }
}