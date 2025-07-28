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
}