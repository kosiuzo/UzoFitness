import SwiftUI
import WatchKit
import UzoFitnessCore

struct WatchWorkoutView: View {
    @StateObject private var viewModel = WatchWorkoutViewModel()
    @State private var showingRestTimer = false
    
    var body: some View {
        NavigationView {
            contentView
                .navigationTitle("Workout")
                .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            AppLogger.debug("🔄 [WatchWorkoutView] Task started - loading workout data", category: "WatchWorkoutView")
            await viewModel.loadWorkoutData()
            viewModel.startPeriodicRefresh()
        }
        .onDisappear {
            AppLogger.debug("🔄 [WatchWorkoutView] View disappearing - stopping periodic refresh", category: "WatchWorkoutView")
            viewModel.stopPeriodicRefresh()
        }
        .sheet(isPresented: $showingRestTimer) {
            WatchRestTimerView()
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch viewModel.state {
        case .idle, .loading:
            loadingView
            
        case .noActiveWorkout:
            noWorkoutView
            
        case .activeWorkout(let exerciseData):
            activeWorkoutView(exerciseData: exerciseData)
            
        case .error(let message):
            WatchErrorView(message: message) {
                Task {
                    await viewModel.loadWorkoutData()
                }
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .accessibilityHidden(true)
            
            Text("Loading...")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .accessibilityLabel("Loading workout data")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
    
    private var noWorkoutView: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.run")
                .font(.system(size: 40))
                .foregroundColor(.orange)
                .accessibilityHidden(true)
            
            Text("No Active Workout")
                .font(.system(size: 18, weight: .semibold))
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            
            Text("Start a workout on your iPhone to see it here")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .accessibilityLabel("Instructions to start workout on iPhone")
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No active workout screen")
    }
    
    private func activeWorkoutView(exerciseData: CurrentExerciseData) -> some View {
        VStack(spacing: 16) {
            // Exercise name
            Text(exerciseData.exerciseName)
                .font(.system(size: 20, weight: .semibold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .accessibilityAddTraits(.isHeader)
                .accessibilityLabel("Current exercise: \(exerciseData.exerciseName)")
            
            // Set progress
            Text("Set \(exerciseData.completedSets + 1) of \(exerciseData.totalSets)")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
                .accessibilityLabel("Set progress: \(exerciseData.completedSets + 1) of \(exerciseData.totalSets) sets")
            
            // Planned reps and weight (if available)
            if let reps = exerciseData.plannedReps {
                HStack(spacing: 8) {
                    Text("\(reps) reps")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                    
                    if let weight = exerciseData.plannedWeight {
                        Text("@ \(Int(weight)) lbs")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 20) {
                // Rest timer button
                Button(action: {
                    AppLogger.debug("🔄 [WatchWorkoutView] Rest timer button tapped", category: "WatchWorkoutView")
                    WKInterfaceDevice.current().play(.click)
                    showingRestTimer = true
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "timer")
                            .font(.system(size: 20))
                        Text("R")
                            .font(.system(size: 12, weight: .medium))
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .frame(width: 60, height: 60)
                .accessibilityLabel("Start rest timer")
                .accessibilityHint("Opens rest timer with preset options")
                
                // Complete set button
                Button(action: {
                    AppLogger.debug("🔄 [WatchWorkoutView] Complete set button tapped", category: "WatchWorkoutView")
                    WKInterfaceDevice.current().play(.click)
                    Task {
                        await viewModel.completeSet()
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 20))
                        Text("Done")
                            .font(.system(size: 12, weight: .medium))
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .frame(width: 60, height: 60)
                .accessibilityLabel("Complete current set")
                .accessibilityHint("Marks the current set as completed")
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Error View

struct WatchErrorView: View {
    let message: String
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.red)
                .accessibilityHidden(true)
            
            Text("Error")
                .font(.system(size: 18, weight: .semibold))
                .accessibilityAddTraits(.isHeader)
            
            Text(message)
                .font(.system(size: 14))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .accessibilityLabel("Error message: \(message)")
            
            Button("Retry") {
                AppLogger.debug("🔄 [WatchWorkoutView] Retry button tapped", category: "WatchWorkoutView")
                WKInterfaceDevice.current().play(.click)
                retry()
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel("Retry loading workout data")
            .accessibilityHint("Attempts to reload workout data from iPhone")
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error screen with retry option")
    }
}

// MARK: - ViewModel

@MainActor
class WatchWorkoutViewModel: ObservableObject {
    @Published var state: WatchWorkoutState = .idle
    
    private var sharedDataManager: SharedDataManagerProtocol?
    private var refreshTimer: Timer?
    private var refreshAttempts = 0
    private let maxRefreshAttempts = 3
    
    init() {
        AppLogger.debug("🔄 [WatchWorkoutViewModel.init] Initializing view model", category: "WatchWorkoutViewModel")
        setupSharedDataManager()
    }
    
    private func setupSharedDataManager() {
        do {
            sharedDataManager = try SharedDataManager()
            AppLogger.debug("✅ [WatchWorkoutViewModel.setupSharedDataManager] Successfully initialized SharedDataManager", category: "WatchWorkoutViewModel")
        } catch {
            AppLogger.error("❌ [WatchWorkoutViewModel.setupSharedDataManager] Failed to initialize SharedDataManager: \(error.localizedDescription)", category: "WatchWorkoutViewModel", error: error)
        }
    }
    
    func loadWorkoutData() async {
        AppLogger.debug("🔄 [WatchWorkoutViewModel.loadWorkoutData] Loading workout data", category: "WatchWorkoutViewModel")
        
        guard let dataManager = sharedDataManager else {
            AppLogger.error("❌ [WatchWorkoutViewModel.loadWorkoutData] SharedDataManager not available", category: "WatchWorkoutViewModel")
            state = .error("Unable to access shared data. Please check App Groups configuration.")
            return
        }
        
        state = .loading
        
        do {
            // Debug App Groups access
            AppLogger.debug("🔄 [WatchWorkoutViewModel.loadWorkoutData] Attempting to read workout data", category: "WatchWorkoutViewModel")
            
            // Get current exercise data
            if let exerciseData = await dataManager.getCurrentExercise() {
                AppLogger.debug("✅ [WatchWorkoutViewModel.loadWorkoutData] Found active workout: \(exerciseData.exerciseName)", category: "WatchWorkoutViewModel")
                state = .activeWorkout(exerciseData)
            } else {
                AppLogger.info("📊 [WatchWorkoutViewModel.loadWorkoutData] No active workout found", category: "WatchWorkoutViewModel")
                state = .noActiveWorkout
            }
        } catch {
            AppLogger.error("❌ [WatchWorkoutViewModel.loadWorkoutData] Error loading workout data: \(error.localizedDescription)", category: "WatchWorkoutViewModel", error: error)
            state = .error("Failed to load workout data. Please try again.")
        }
    }
    
    func startPeriodicRefresh() {
        AppLogger.debug("🔄 [WatchWorkoutViewModel.startPeriodicRefresh] Starting periodic refresh", category: "WatchWorkoutViewModel")
        
        // Reset attempt counter
        refreshAttempts = 0
        
        // Stop any existing timer
        stopPeriodicRefresh()
        
        // Start a new timer that refreshes every 2 seconds
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshWorkoutData()
            }
        }
    }
    
    func stopPeriodicRefresh() {
        AppLogger.debug("🔄 [WatchWorkoutViewModel.stopPeriodicRefresh] Stopping periodic refresh", category: "WatchWorkoutViewModel")
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    private func refreshWorkoutData() {
        refreshAttempts += 1
        AppLogger.debug("🔄 [WatchWorkoutViewModel] Timer triggered - refreshing workout data (attempt \(refreshAttempts)/\(maxRefreshAttempts))", category: "WatchWorkoutViewModel")
        
        Task {
            await loadWorkoutData()
            
            // Check if we should stop trying
            if refreshAttempts >= maxRefreshAttempts {
                AppLogger.info("📊 [WatchWorkoutViewModel] Reached maximum refresh attempts (\(maxRefreshAttempts)), stopping periodic refresh", category: "WatchWorkoutViewModel")
                stopPeriodicRefresh()
            }
        }
    }
    
    func completeSet() async {
        AppLogger.debug("🔄 [WatchWorkoutViewModel.completeSet] Completing set", category: "WatchWorkoutViewModel")
        
        guard case .activeWorkout(let exerciseData) = state,
              let dataManager = sharedDataManager else {
            AppLogger.error("❌ [WatchWorkoutViewModel.completeSet] No active workout or data manager", category: "WatchWorkoutViewModel")
            return
        }
        
        do {
            // Mark set as completed
            try await dataManager.markSetCompleted(
                exerciseId: exerciseData.exerciseId,
                setIndex: exerciseData.currentSetIndex
            )
            
            // Provide haptic feedback
            WKInterfaceDevice.current().play(.success)
            
            // Reload workout data to get updated state
            await loadWorkoutData()
            
            AppLogger.debug("✅ [WatchWorkoutViewModel.completeSet] Set completed successfully", category: "WatchWorkoutViewModel")
        } catch {
            // Provide error haptic feedback
            WKInterfaceDevice.current().play(.failure)
            
            AppLogger.error("❌ [WatchWorkoutViewModel.completeSet] Error: \(error.localizedDescription)", category: "WatchWorkoutViewModel", error: error)
        }
    }
}

// MARK: - State Management

enum WatchWorkoutState {
    case idle
    case loading
    case noActiveWorkout
    case activeWorkout(CurrentExerciseData)
    case error(String)
}

// MARK: - Previews

#Preview {
    WatchWorkoutView()
} 