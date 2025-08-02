import Foundation
import SwiftData
import Combine
import UIKit

// MARK: - Settings ViewModel
@MainActor
class SettingsViewModel: ObservableObject {
    // MARK: - Published State
    @Published var isHealthKitEnabled: Bool = false
    @Published var isPhotoAccessGranted: Bool = false
    @Published var error: Error?
    @Published var state: SettingsLoadingState = .idle
    
    // MARK: - Private Properties
    private let healthKitManager: HealthKitManager
    private let photoService: PhotoService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(
        healthKitManager: HealthKitManager,
        photoService: PhotoService
    ) {
        self.healthKitManager = healthKitManager
        self.photoService = photoService
        
        AppLogger.debug("[SettingsViewModel.init] Initialized with dependencies", category: "SettingsViewModel")
        
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
    case permissionDenied(String)
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied(let service):
            return "Permission denied for \(service). Please check your privacy settings."
        case .networkError:
            return "Network error. Please check your internet connection."
        }
    }
} 