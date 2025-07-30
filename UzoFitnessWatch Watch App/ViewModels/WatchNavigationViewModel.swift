import Foundation
import SwiftData
import Combine
import WatchKit
import UzoFitnessCore

// MARK: - Watch App Tab (Minimalist Design)
enum WatchTab: String, CaseIterable {
    case workout = "Workout"
    case timer = "Timer"
    
    var systemImage: String {
        switch self {
        case .workout: return "figure.strengthtraining.traditional"
        case .timer: return "timer"
        }
    }
}

// MARK: - Watch Navigation State
enum WatchNavigationState {
    case loading
    case ready
    case error(String)
}

// MARK: - Watch Navigation ViewModel
@MainActor
public final class WatchNavigationViewModel: ObservableObject {
    
    // MARK: - Published State
    @Published var selectedTab: WatchTab = .workout
    @Published var navigationState: WatchNavigationState = .loading
    @Published var isConnectedToPhone: Bool = false
    @Published var lastSyncTime: Date?
    
    // MARK: - Child ViewModels (Minimalist Design)
    @Published var workoutViewModel: WatchWorkoutViewModel?
    @Published var timerViewModel: WatchTimerViewModel?
    
    // MARK: - Dependencies
    private let modelContext: ModelContext
    private let syncCoordinator: SyncCoordinatorProtocol
    private let sharedData: SharedDataProtocol
    
    // MARK: - Private State
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    internal init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.syncCoordinator = SyncCoordinator.shared
        self.sharedData = SharedDataManager.shared
        
        initializeApp()
    }
    
    // MARK: - App Initialization
    private func initializeApp() {
        navigationState = .loading
        
        Task { @MainActor in
            do {
                AppLogger.info("[WatchNavigationViewModel] Starting app initialization", category: "WatchNavigation")
                
                // Initialize sync coordinator
                syncCoordinator.initialize()
                AppLogger.debug("[WatchNavigationViewModel] Sync coordinator initialized", category: "WatchNavigation")
                
                // Setup observers
                setupObservers()
                AppLogger.debug("[WatchNavigationViewModel] Observers setup completed", category: "WatchNavigation")
                
                // Initialize child view models
                initializeChildViewModels()
                AppLogger.debug("[WatchNavigationViewModel] Child view models initialized", category: "WatchNavigation")
                
                // Removed user flow coordinator for minimalist design
                
                // Check initial connectivity (don't wait for this)
                Task.detached {
                    await MainActor.run {
                        self.checkConnectivity()
                    }
                }
                
                // Set to ready state
                navigationState = .ready
                AppLogger.info("[WatchNavigationViewModel] App initialized successfully - State set to READY", category: "WatchNavigation")
                
            } catch {
                AppLogger.error("[WatchNavigationViewModel] App initialization failed: \(error.localizedDescription)", category: "WatchNavigation")
                navigationState = .error("Initialization failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func setupObservers() {
        // Observe sync coordinator connection state
        if let syncCoordinator = syncCoordinator as? SyncCoordinator {
            syncCoordinator.$state
                .receive(on: DispatchQueue.main)
                .sink { [weak self] state in
                    self?.handleSyncStateChange(state)
                }
                .store(in: &cancellables)
        }
        
        // Add sync event handler
        syncCoordinator.addSyncEventHandler { [weak self] event in
            self?.handleSyncEvent(event)
        }
    }
    
    private func initializeChildViewModels() {
        do {
            // Initialize workout view model
            workoutViewModel = WatchWorkoutViewModel(
                modelContext: modelContext,
                syncCoordinator: SyncCoordinator.shared,
                sharedData: sharedData,
                calendar: CalendarService()
            )
            AppLogger.debug("[WatchNavigationViewModel] Workout view model initialized", category: "WatchNavigation")
            
            // Initialize timer view model
            timerViewModel = WatchTimerViewModel(
                syncCoordinator: SyncCoordinator.shared,
                sharedData: sharedData
            )
            AppLogger.debug("[WatchNavigationViewModel] Timer view model initialized", category: "WatchNavigation")
            
        } catch {
            AppLogger.error("[WatchNavigationViewModel] Failed to initialize child view models: \(error.localizedDescription)", category: "WatchNavigation")
            // Set a minimal state to prevent app from hanging
            workoutViewModel = nil
            timerViewModel = nil
        }
        
        AppLogger.debug("[WatchNavigationViewModel] Child view models initialized", category: "WatchNavigation")
    }
    
    // MARK: - Removed UserFlowCoordinator for minimalist design
    
    // MARK: - Tab Management
    func selectTab(_ tab: WatchTab) {
        guard selectedTab != tab else { return }
        
        selectedTab = tab
        
        // Haptic feedback for tab change
        WKInterfaceDevice.current().play(.click)
        
        AppLogger.debug("[WatchNavigationViewModel] Selected tab: \(tab.rawValue)", category: "WatchNavigation")
    }
    
    // MARK: - Connectivity Management
    private func checkConnectivity() {
        isConnectedToPhone = syncCoordinator.isConnected
        
        AppLogger.info("[WatchNavigationViewModel] Connectivity check: \(isConnectedToPhone ? "Connected" : "Disconnected")", category: "WatchNavigation")
        
        if isConnectedToPhone {
            // Request full sync when connected
            syncCoordinator.requestFullSync()
            lastSyncTime = Date()
        }
    }
    
    public func retryConnection() {
        syncCoordinator.initialize()
        checkConnectivity()
    }
    
    // MARK: - Testing Methods (Simplified)
    public func sendTestMessage() {
        if let syncCoord = syncCoordinator as? SyncCoordinator {
            syncCoord.sendTestMessage()
        }
    }
    
    // MARK: - Sync State Handling
    private func handleSyncStateChange(_ state: SyncState) {
        switch state {
        case .idle:
            isConnectedToPhone = syncCoordinator.isConnected
            
        case .syncing:
            isConnectedToPhone = true
            
        case .completed:
            isConnectedToPhone = true
            lastSyncTime = Date()
            
        case .error(_):
            isConnectedToPhone = false
        }
    }
    
    private func handleSyncEvent(_ event: SyncEvent) {
        lastSyncTime = Date()
        
        switch event.type {
        case .workoutStarted:
            if event.deviceSource == .iPhone {
                // Switch to workout tab when workout starts on iPhone
                selectedTab = .workout
            }
            
        case .timerStarted:
            if event.deviceSource == .iPhone {
                // Switch to timer tab when timer starts on iPhone
                selectedTab = .timer
            }
            
        case .fullSync:
            AppLogger.info("[WatchNavigationViewModel] Full sync completed", category: "WatchNavigation")
            
        default:
            break
        }
    }
    
    // MARK: - App Lifecycle
    public func handleAppWillEnterForeground() {
        // Check connectivity when app becomes active
        checkConnectivity()
        
        // Process any pending sync operations
        syncCoordinator.processPendingOperations()
        
        AppLogger.debug("[WatchNavigationViewModel] App entered foreground", category: "WatchNavigation")
    }
    
    public func handleAppDidEnterBackground() {
        // Ensure data is saved when app goes to background
        _ = sharedData.synchronize()
        
        AppLogger.debug("[WatchNavigationViewModel] App entered background", category: "WatchNavigation")
    }
    
    // MARK: - Error Handling
    public func dismissError() {
        if case .error(_) = navigationState {
            navigationState = .ready
        }
    }
    
    public func retryAfterError() {
        initializeApp()
    }
    
    public func forceReadyState() {
        AppLogger.warning("[WatchNavigationViewModel] Forcing ready state due to timeout", category: "WatchNavigation")
        navigationState = .ready
    }
    
    // MARK: - Helper Methods
    public var isAppReady: Bool {
        if case .ready = navigationState {
            return true
        }
        return false
    }
    
    public var errorMessage: String? {
        if case .error(let message) = navigationState {
            return message
        }
        return nil
    }
    
    public var connectionStatusText: String {
        if isConnectedToPhone {
            if let lastSync = lastSyncTime {
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                return "Synced \(formatter.string(from: lastSync))"
            } else {
                return "Connected"
            }
        } else {
            return "Disconnected"
        }
    }
    
    // MARK: - Cleanup
    deinit {
        // Note: deinit is synchronous, async cleanup should be handled elsewhere
        AppLogger.debug("[WatchNavigationViewModel] Deinitialized", category: "WatchNavigation")
    }
}

// MARK: - ModelContext Extension for Preview
extension ModelContext {
    @MainActor
    static var previewNavigation: ModelContext {
        let container = try! ModelContainer(for: Exercise.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        return container.mainContext
    }
}