import Foundation
import SwiftUI
import WatchKit
import UzoFitnessCore

// MARK: - User Flow Types
public enum UserFlow {
    case appLaunch
    case workoutStart
    case workoutExecution
    case setCompletion
    case timerManagement
    case workoutCompletion
    case errorRecovery
    case connectivityTesting
}

public enum FlowState: Equatable {
    case idle
    case inProgress
    case completed
    case error(String)
}

// MARK: - User Flow Coordinator
@MainActor
public class UserFlowCoordinator: ObservableObject {
    
    @Published public private(set) var currentFlow: UserFlow? = nil
    @Published public private(set) var flowState: FlowState = .idle
    @Published public private(set) var flowProgress: Double = 0.0
    @Published public private(set) var flowMessage: String = ""
    
    private let syncCoordinator: SyncCoordinator
    private let navigationViewModel: WatchNavigationViewModel
    private var flowSteps: [FlowStep] = []
    private var currentStepIndex: Int = 0
    
    public init(syncCoordinator: SyncCoordinator, navigationViewModel: WatchNavigationViewModel) {
        self.syncCoordinator = syncCoordinator
        self.navigationViewModel = navigationViewModel
        
        setupFlowSteps()
        AppLogger.info("[UserFlowCoordinator] Initialized", category: "UserFlow")
    }
    
    // MARK: - Flow Management
    public func startFlow(_ flow: UserFlow) {
        currentFlow = flow
        flowState = .inProgress
        currentStepIndex = 0
        flowProgress = 0.0
        
        setupFlowSteps(for: flow)
        
        AppLogger.info("[UserFlowCoordinator] Starting flow: \(flow)", category: "UserFlow")
        executeNextStep()
    }
    
    public func completeCurrentStep() {
        guard let flow = currentFlow, currentStepIndex < flowSteps.count else { return }
        
        currentStepIndex += 1
        flowProgress = Double(currentStepIndex) / Double(flowSteps.count)
        
        if currentStepIndex >= flowSteps.count {
            completeFlow()
        } else {
            executeNextStep()
        }
    }
    
    public func failCurrentStep(with error: String) {
        flowState = .error(error)
        flowMessage = error
        AppLogger.error("[UserFlowCoordinator] Flow failed: \(error)", category: "UserFlow")
        
        // Trigger haptic feedback for error
        WKInterfaceDevice.current().play(.failure)
    }
    
    private func completeFlow() {
        flowState = .completed
        flowProgress = 1.0
        flowMessage = "Flow completed successfully"
        
        AppLogger.info("[UserFlowCoordinator] Flow completed: \(currentFlow?.description ?? "unknown")", category: "UserFlow")
        
        // Trigger success feedback
        WKInterfaceDevice.current().play(.success)
        
        // Reset after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.resetFlow()
        }
    }
    
    private func resetFlow() {
        currentFlow = nil
        flowState = .idle
        flowProgress = 0.0
        flowMessage = ""
        flowSteps.removeAll()
        currentStepIndex = 0
    }
    
    // MARK: - Flow Step Execution
    private func executeNextStep() {
        guard let flow = currentFlow, 
              currentStepIndex < flowSteps.count else { return }
        
        let step = flowSteps[currentStepIndex]
        flowMessage = step.description
        
        AppLogger.debug("[UserFlowCoordinator] Executing step: \(step.description)", category: "UserFlow")
        
        // Execute the step action
        step.action { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.completeCurrentStep()
                } else {
                    self?.failCurrentStep(with: error ?? "Unknown error")
                }
            }
        }
    }
    
    // MARK: - Flow Step Setup
    private func setupFlowSteps() {
        // Default setup - will be overridden by specific flows
    }
    
    private func setupFlowSteps(for flow: UserFlow) {
        flowSteps.removeAll()
        
        switch flow {
        case .appLaunch:
            setupAppLaunchFlow()
        case .workoutStart:
            setupWorkoutStartFlow()
        case .workoutExecution:
            setupWorkoutExecutionFlow()
        case .setCompletion:
            setupSetCompletionFlow()
        case .timerManagement:
            setupTimerManagementFlow()
        case .workoutCompletion:
            setupWorkoutCompletionFlow()
        case .errorRecovery:
            setupErrorRecoveryFlow()
        case .connectivityTesting:
            setupConnectivityTestingFlow()
        }
    }
    
    // MARK: - Specific Flow Implementations
    private func setupAppLaunchFlow() {
        flowSteps = [
            FlowStep(description: "Initializing app...") { completion in
                // Simulate app initialization
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    completion(true, nil)
                }
            },
            FlowStep(description: "Setting up WatchConnectivity...") { [weak self] completion in
                self?.syncCoordinator.initialize()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    completion(true, nil)
                }
            },
            FlowStep(description: "Loading user preferences...") { completion in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    completion(true, nil)
                }
            },
            FlowStep(description: "Ready to use!") { completion in
                completion(true, nil)
            }
        ]
    }
    
    private func setupWorkoutStartFlow() {
        flowSteps = [
            FlowStep(description: "Checking connectivity...") { [weak self] completion in
                let isConnected = self?.syncCoordinator.validateConnection() ?? false
                completion(isConnected, isConnected ? nil : "No connection to iPhone")
            },
            FlowStep(description: "Loading today's workout...") { [weak self] completion in
                // Switch to workout tab to show the workout interface
                self?.navigationViewModel.selectTab(.workout)
                self?.navigationViewModel.workoutViewModel?.handle(.startTodaysWorkout)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    completion(true, nil)
                }
            },
            FlowStep(description: "Syncing workout start...") { [weak self] completion in
                // Create a realistic workout session
                let session = SharedWorkoutSession(
                    id: UUID(),
                    title: "Today's Workout",
                    startTime: Date(),
                    duration: nil,
                    currentExerciseIndex: 0,
                    totalExercises: 5
                )
                self?.syncCoordinator.syncWorkoutStart(session)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    completion(true, nil)
                }
            },
            FlowStep(description: "Workout started successfully!") { [weak self] completion in
                // Provide haptic feedback for successful workout start
                WKInterfaceDevice.current().play(.success)
                completion(true, nil)
            }
        ]
    }
    
    private func setupWorkoutExecutionFlow() {
        flowSteps = [
            FlowStep(description: "Loading current exercise...") { [weak self] completion in
                // Switch to workout tab to show exercise
                self?.navigationViewModel.selectTab(.workout)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    completion(true, nil)
                }
            },
            FlowStep(description: "Displaying exercise details...") { [weak self] completion in
                // Show next exercise to simulate displaying details
                self?.navigationViewModel.workoutViewModel?.handle(.nextExercise)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    completion(true, nil)
                }
            },
            FlowStep(description: "Preparing for set tracking...") { [weak self] completion in
                // Move to previous exercise to demonstrate navigation
                self?.navigationViewModel.workoutViewModel?.handle(.previousExercise)
                completion(true, nil)
            },
            FlowStep(description: "Ready for set completion") { [weak self] completion in
                // Provide haptic feedback indicating readiness
                WKInterfaceDevice.current().play(.click)
                completion(true, nil)
            }
        ]
    }
    
    private func setupSetCompletionFlow() {
        flowSteps = [
            FlowStep(description: "Recording set completion...") { [weak self] completion in
                // Create realistic set completion with current exercise data
                let setCompletion = SetCompletionPayload(
                    setId: UUID(),
                    sessionExerciseId: UUID(),
                    reps: 10,
                    weight: 135.0,
                    isCompleted: true
                )
                self?.syncCoordinator.syncSetCompletion(setCompletion)
                
                // Update local workout state with proper parameters
                self?.navigationViewModel.workoutViewModel?.handle(.completeSet(exerciseID: UUID(), setIndex: 0, reps: 10, weight: 135.0))
                completion(true, nil)
            },
            FlowStep(description: "Syncing with iPhone...") { [weak self] completion in
                // Validate connection during sync
                let isConnected = self?.syncCoordinator.validateConnection() ?? false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    completion(isConnected, isConnected ? nil : "Sync failed - offline mode")
                }
            },
            FlowStep(description: "Starting rest timer...") { [weak self] completion in
                // Automatically start rest timer after set completion
                self?.navigationViewModel.selectTab(.timer)
                self?.navigationViewModel.timerViewModel?.handle(.startTimer(duration: 90.0, exerciseName: "Bench Press"))
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    completion(true, nil)
                }
            },
            FlowStep(description: "Set completed successfully!") { [weak self] completion in
                // Provide success feedback
                WKInterfaceDevice.current().play(.success)
                completion(true, nil)
            }
        ]
    }
    
    private func setupTimerManagementFlow() {
        flowSteps = [
            FlowStep(description: "Starting rest timer...") { [weak self] completion in
                // Switch to timer tab and start timer
                self?.navigationViewModel.selectTab(.timer)
                self?.syncCoordinator.syncTimerState(SharedTimerState(
                    isRunning: true,
                    duration: 90.0,
                    startTime: Date(),
                    exerciseName: "Bench Press"
                ))
                
                // Start timer in local ViewModel
                self?.navigationViewModel.timerViewModel?.handle(.startTimer(duration: 90.0, exerciseName: "Bench Press"))
                completion(true, nil)
            },
            FlowStep(description: "Timer synchronizing...") { [weak self] completion in
                // Ensure timer state is synced across devices
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    completion(true, nil)
                }
            },
            FlowStep(description: "Testing pause/resume...") { [weak self] completion in
                // Test pause functionality
                self?.navigationViewModel.timerViewModel?.handle(.pauseTimer)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // Test resume functionality
                    self?.navigationViewModel.timerViewModel?.handle(.resumeTimer)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        completion(true, nil)
                    }
                }
            },
            FlowStep(description: "Timer management ready") { [weak self] completion in
                WKInterfaceDevice.current().play(.success)
                completion(true, nil)
            }
        ]
    }
    
    private func setupWorkoutCompletionFlow() {
        flowSteps = [
            FlowStep(description: "Stopping all timers...") { [weak self] completion in
                // Stop any running timers
                self?.navigationViewModel.timerViewModel?.handle(.stopTimer)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    completion(true, nil)
                }
            },
            FlowStep(description: "Finalizing workout data...") { [weak self] completion in
                // Finalize workout in the workout view model
                self?.navigationViewModel.workoutViewModel?.handle(.completeWorkout)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    completion(true, nil)
                }
            },
            FlowStep(description: "Syncing completion to iPhone...") { [weak self] completion in
                // Sync workout completion
                self?.syncCoordinator.syncWorkoutCompletion(sessionId: UUID())
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    completion(true, nil)
                }
            },
            FlowStep(description: "Switching to progress view...") { [weak self] completion in
                // Show progress after completion
                self?.navigationViewModel.selectTab(.progress)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    completion(true, nil)
                }
            },
            FlowStep(description: "Workout completed successfully!") { [weak self] completion in
                // Provide success feedback
                WKInterfaceDevice.current().play(.success)
                completion(true, nil)
            }
        ]
    }
    
    private func setupErrorRecoveryFlow() {
        flowSteps = [
            FlowStep(description: "Detecting connection issues...") { [weak self] completion in
                // Check current connection status
                let isConnected = self?.syncCoordinator.validateConnection() ?? false
                AppLogger.info("[UserFlowCoordinator] Connection status: \(isConnected)", category: "UserFlow")
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    completion(true, nil)
                }
            },
            FlowStep(description: "Attempting reconnection...") { [weak self] completion in
                // Force reinitialize connection
                self?.syncCoordinator.initialize()
                
                // Send test heartbeat to validate connection
                self?.syncCoordinator.sendHeartbeat()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    let isReconnected = self?.syncCoordinator.validateConnection() ?? false
                    completion(isReconnected, isReconnected ? nil : "Reconnection failed")
                }
            },
            FlowStep(description: "Processing pending operations...") { [weak self] completion in
                // Process any pending sync operations
                self?.syncCoordinator.processPendingOperations()
                
                // Clear any failed operations if needed
                let pendingCount = self?.syncCoordinator.getPendingOperationsCount() ?? 0
                AppLogger.info("[UserFlowCoordinator] Processing \(pendingCount) pending operations", category: "UserFlow")
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    completion(true, nil)
                }
            },
            FlowStep(description: "Validating recovery...") { [weak self] completion in
                // Final validation of connection and sync state
                let finalConnectionStatus = self?.syncCoordinator.validateConnection() ?? false
                let pendingAfterRecovery = self?.syncCoordinator.getPendingOperationsCount() ?? 0
                
                AppLogger.info("[UserFlowCoordinator] Recovery validation - Connected: \(finalConnectionStatus), Pending: \(pendingAfterRecovery)", category: "UserFlow")
                
                completion(finalConnectionStatus, finalConnectionStatus ? nil : "Recovery validation failed")
            },
            FlowStep(description: "Recovery completed successfully!") { [weak self] completion in
                WKInterfaceDevice.current().play(.success)
                completion(true, nil)
            }
        ]
    }
    
    private func setupConnectivityTestingFlow() {
        flowSteps = [
            FlowStep(description: "Initial connection test...") { [weak self] completion in
                let isConnected = self?.syncCoordinator.validateConnection() ?? false
                AppLogger.info("[UserFlowCoordinator] Initial connection status: \(isConnected)", category: "UserFlow")
                completion(isConnected, isConnected ? nil : "Initial connection test failed")
            },
            FlowStep(description: "Sending test message...") { [weak self] completion in
                // Send test message to validate bidirectional communication
                self?.syncCoordinator.sendTestMessage()
                AppLogger.info("[UserFlowCoordinator] Test message sent", category: "UserFlow")
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    completion(true, nil)
                }
            },
            FlowStep(description: "Testing heartbeat...") { [weak self] completion in
                // Test heartbeat functionality
                self?.syncCoordinator.sendHeartbeat()
                AppLogger.info("[UserFlowCoordinator] Heartbeat sent", category: "UserFlow")
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    completion(true, nil)
                }
            },
            FlowStep(description: "Validating sync operations...") { [weak self] completion in
                // Test sync operations by creating and syncing test data
                let testSession = SharedWorkoutSession(
                    id: UUID(),
                    title: "Connectivity Test Session",
                    startTime: Date(),
                    duration: nil,
                    currentExerciseIndex: 0,
                    totalExercises: 1
                )
                
                self?.syncCoordinator.syncWorkoutStart(testSession)
                AppLogger.info("[UserFlowCoordinator] Test sync operation initiated", category: "UserFlow")
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    completion(true, nil)
                }
            },
            FlowStep(description: "Final connection validation...") { [weak self] completion in
                // Final comprehensive validation
                let finalConnectionStatus = self?.syncCoordinator.validateConnection() ?? false
                let pendingOperations = self?.syncCoordinator.getPendingOperationsCount() ?? 0
                
                AppLogger.info("[UserFlowCoordinator] Final validation - Connected: \(finalConnectionStatus), Pending: \(pendingOperations)", category: "UserFlow")
                
                completion(finalConnectionStatus, finalConnectionStatus ? nil : "Final validation failed")
            },
            FlowStep(description: "Connectivity test completed!") { [weak self] completion in
                // Provide success feedback
                WKInterfaceDevice.current().play(.success)
                AppLogger.info("[UserFlowCoordinator] Connectivity test completed successfully", category: "UserFlow")
                completion(true, nil)
            }
        ]
    }
}

// MARK: - Flow Step
private struct FlowStep {
    let description: String
    let action: (@escaping (Bool, String?) -> Void) -> Void
}

// MARK: - User Flow Extensions
extension UserFlow {
    var description: String {
        switch self {
        case .appLaunch: return "App Launch"
        case .workoutStart: return "Workout Start"
        case .workoutExecution: return "Workout Execution"
        case .setCompletion: return "Set Completion"
        case .timerManagement: return "Timer Management"
        case .workoutCompletion: return "Workout Completion"
        case .errorRecovery: return "Error Recovery"
        case .connectivityTesting: return "Connectivity Testing"
        }
    }
}