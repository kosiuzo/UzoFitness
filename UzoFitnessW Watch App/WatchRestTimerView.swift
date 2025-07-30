import SwiftUI
import WatchKit
import UzoFitnessCore

struct WatchRestTimerView: View {
    @StateObject private var viewModel = WatchRestTimerViewModel()
    @Environment(\.dismiss) private var dismiss
    
    let presetDurations: [TimeInterval] = [30, 60, 90, 120]
    
    var body: some View {
        NavigationView {
            contentView
                .navigationTitle("Rest Timer")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            AppLogger.debug("🔄 [WatchRestTimerView] Done button tapped", category: "WatchRestTimerView")
                            Task {
                                await viewModel.stopTimer()
                            }
                            dismiss()
                        }
                    }
                }
        }
        .task {
            AppLogger.debug("🔄 [WatchRestTimerView] Task started - loading timer state", category: "WatchRestTimerView")
            await viewModel.loadTimerState()
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch viewModel.state {
        case .idle, .loading:
            loadingView
            
        case .selectDuration:
            presetSelectionView
            
        case .running(let remainingTime, let totalDuration):
            runningTimerView(remainingTime: remainingTime, totalDuration: totalDuration)
            
        case .paused(let remainingTime, let totalDuration):
            pausedTimerView(remainingTime: remainingTime, totalDuration: totalDuration)
            
        case .finished:
            finishedView
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .accessibilityHidden(true)
            
            Text("Loading...")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .accessibilityLabel("Loading timer data")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
    
    // MARK: - Preset Selection View
    
    private var presetSelectionView: some View {
        VStack(spacing: 16) {
            Text("Choose Rest Time")
                .font(.system(size: 18, weight: .semibold))
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(presetDurations, id: \.self) { duration in
                    Button(action: {
                        AppLogger.debug("🔄 [WatchRestTimerView] Preset \(Int(duration))s selected", category: "WatchRestTimerView")
                        WKInterfaceDevice.current().play(.click)
                        Task {
                            await viewModel.startTimer(duration: duration)
                        }
                    }) {
                        VStack(spacing: 4) {
                            Text("\(Int(duration))")
                                .font(.system(size: 20, weight: .bold))
                            Text("sec")
                                .font(.system(size: 12))
                        }
                        .frame(width: 60, height: 60)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .accessibilityLabel("\(Int(duration)) second rest timer")
                    .accessibilityHint("Starts a \(Int(duration)) second rest timer")
                }
            }
        }
        .padding()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Rest timer duration selection")
    }
    
    // MARK: - Running Timer View
    
    private func runningTimerView(remainingTime: TimeInterval, totalDuration: TimeInterval) -> some View {
        VStack(spacing: 20) {
            // Timer display
            VStack(spacing: 8) {
                Text(formatTime(remainingTime))
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .monospacedDigit()
                    .accessibilityLabel("Timer: \(formatTime(remainingTime)) remaining")
                
                Text("remaining")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
            }
            
            // Progress ring (visual indicator)
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                
                Circle()
                    .trim(from: 0, to: (totalDuration - remainingTime) / totalDuration)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: remainingTime)
            }
            .frame(width: 80, height: 80)
            
            // Control buttons
            VStack(spacing: 12) {
                // Time adjustment buttons
                HStack(spacing: 20) {
                    Button(action: {
                        AppLogger.debug("🔄 [WatchRestTimerView] Subtract 30s button tapped", category: "WatchRestTimerView")
                        WKInterfaceDevice.current().play(.click)
                        Task {
                            await viewModel.adjustTimer(by: -30)
                        }
                    }) {
                        VStack(spacing: 2) {
                            Image(systemName: "minus")
                                .font(.system(size: 16))
                            Text("30s")
                                .font(.system(size: 10))
                        }
                    }
                    .buttonStyle(.bordered)
                    .frame(width: 50, height: 50)
                    .accessibilityLabel("Subtract 30 seconds")
                    .accessibilityHint("Reduces timer by 30 seconds")
                    
                    Button(action: {
                        AppLogger.debug("🔄 [WatchRestTimerView] Pause button tapped", category: "WatchRestTimerView")
                        WKInterfaceDevice.current().play(.click)
                        Task {
                            await viewModel.pauseTimer()
                        }
                    }) {
                        VStack(spacing: 2) {
                            Image(systemName: "pause.fill")
                                .font(.system(size: 16))
                            Text("Pause")
                                .font(.system(size: 10))
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .frame(width: 50, height: 50)
                    .accessibilityLabel("Pause timer")
                    .accessibilityHint("Pauses the running timer")
                    
                    Button(action: {
                        AppLogger.debug("🔄 [WatchRestTimerView] Add 30s button tapped", category: "WatchRestTimerView")
                        WKInterfaceDevice.current().play(.click)
                        Task {
                            await viewModel.adjustTimer(by: 30)
                        }
                    }) {
                        VStack(spacing: 2) {
                            Image(systemName: "plus")
                                .font(.system(size: 16))
                            Text("30s")
                                .font(.system(size: 10))
                        }
                    }
                    .buttonStyle(.bordered)
                    .frame(width: 50, height: 50)
                    .accessibilityLabel("Add 30 seconds")
                    .accessibilityHint("Increases timer by 30 seconds")
                }
                
                // Stop button
                Button(action: {
                    AppLogger.debug("🔄 [WatchRestTimerView] Stop button tapped", category: "WatchRestTimerView")
                    WKInterfaceDevice.current().play(.click)
                    Task {
                        await viewModel.stopTimer()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 12))
                        Text("Stop")
                            .font(.system(size: 12))
                    }
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .accessibilityLabel("Stop timer")
                .accessibilityHint("Stops and resets the timer")
            }
        }
        .padding()
    }
    
    // MARK: - Paused Timer View
    
    private func pausedTimerView(remainingTime: TimeInterval, totalDuration: TimeInterval) -> some View {
        VStack(spacing: 20) {
            // Timer display
            VStack(spacing: 8) {
                Text(formatTime(remainingTime))
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .monospacedDigit()
                    .accessibilityLabel("Timer paused: \(formatTime(remainingTime)) remaining")
                
                Text("paused")
                    .font(.system(size: 14))
                    .foregroundColor(.orange)
                    .accessibilityHidden(true)
            }
            
            // Resume button
            Button(action: {
                AppLogger.debug("🔄 [WatchRestTimerView] Resume button tapped", category: "WatchRestTimerView")
                WKInterfaceDevice.current().play(.click)
                Task {
                    await viewModel.resumeTimer()
                }
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 20))
                    Text("Resume")
                        .font(.system(size: 12))
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .frame(width: 80, height: 80)
            
            // Stop button
            Button(action: {
                AppLogger.debug("🔄 [WatchRestTimerView] Stop button tapped", category: "WatchRestTimerView")
                WKInterfaceDevice.current().play(.click)
                Task {
                    await viewModel.stopTimer()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 12))
                    Text("Stop")
                        .font(.system(size: 12))
                }
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .accessibilityLabel("Stop timer")
            .accessibilityHint("Stops and resets the timer")
        }
        .padding()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Paused timer screen")
    }
    
    // MARK: - Finished View
    
    private var finishedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
                .accessibilityHidden(true)
            
            Text("Rest Complete!")
                .font(.system(size: 18, weight: .semibold))
                .accessibilityAddTraits(.isHeader)
            
            Text("Time to get back to work")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .accessibilityLabel("Rest period completed, ready to continue workout")
            
            Button(action: {
                AppLogger.debug("🔄 [WatchRestTimerView] Start new timer button tapped", category: "WatchRestTimerView")
                WKInterfaceDevice.current().play(.click)
                viewModel.resetTimer()
            }) {
                Text("New Timer")
                    .font(.system(size: 16, weight: .medium))
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel("Start new timer")
            .accessibilityHint("Opens timer duration selection")
        }
        .padding()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Timer completed screen")
    }
    
    // MARK: - Helper Methods
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Error View

struct WatchTimerErrorView: View {
    let message: String
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.red)
                .accessibilityHidden(true)
            
            Text("Timer Error")
                .font(.system(size: 18, weight: .semibold))
                .accessibilityAddTraits(.isHeader)
            
            Text(message)
                .font(.system(size: 14))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .accessibilityLabel("Error message: \(message)")
            
            Button("Retry") {
                AppLogger.debug("🔄 [WatchRestTimerView] Retry button tapped", category: "WatchRestTimerView")
                WKInterfaceDevice.current().play(.click)
                retry()
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel("Retry timer operation")
            .accessibilityHint("Attempts to restart the timer")
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Timer error screen with retry option")
    }
}

// MARK: - ViewModel

@MainActor
class WatchRestTimerViewModel: ObservableObject {
    @Published var state: WatchTimerState = .idle
    
    private var sharedDataManager: SharedDataManagerProtocol?
    private var timer: Timer?
    
    init() {
        AppLogger.debug("🔄 [WatchRestTimerViewModel.init] Initializing timer view model", category: "WatchRestTimerViewModel")
        setupSharedDataManager()
    }
    
    deinit {
        timer?.invalidate()
        AppLogger.debug("🔄 [WatchRestTimerViewModel.deinit] Timer invalidated", category: "WatchRestTimerViewModel")
    }
    
    private func setupSharedDataManager() {
        do {
            sharedDataManager = try SharedDataManager()
            AppLogger.debug("✅ [WatchRestTimerViewModel.setupSharedDataManager] Successfully initialized SharedDataManager", category: "WatchRestTimerViewModel")
        } catch {
            AppLogger.error("❌ [WatchRestTimerViewModel.setupSharedDataManager] Failed to initialize SharedDataManager: \(error.localizedDescription)", category: "WatchRestTimerViewModel", error: error)
        }
    }
    
    func loadTimerState() async {
        AppLogger.debug("🔄 [WatchRestTimerViewModel.loadTimerState] Loading timer state", category: "WatchRestTimerViewModel")
        
        guard let dataManager = sharedDataManager else {
            AppLogger.error("❌ [WatchRestTimerViewModel.loadTimerState] SharedDataManager not available", category: "WatchRestTimerViewModel")
            state = .selectDuration
            return
        }
        
        state = .loading
        
        if let timerState = await dataManager.getRestTimerState() {
            if timerState.isActive, let startTime = timerState.startTime {
                // Calculate remaining time
                let elapsed = Date().timeIntervalSince(startTime)
                let remaining = max(0, timerState.duration - elapsed)
                
                if remaining > 0 {
                    AppLogger.debug("✅ [WatchRestTimerViewModel.loadTimerState] Found active timer", category: "WatchRestTimerViewModel")
                    state = .running(remainingTime: remaining, totalDuration: timerState.duration)
                    startTimerUpdates()
                } else {
                    AppLogger.info("📊 [WatchRestTimerViewModel.loadTimerState] Found paused timer", category: "WatchRestTimerViewModel")
                    state = .paused(remainingTime: timerState.remainingTime, totalDuration: timerState.duration)
                }
            } else {
                AppLogger.info("📊 [WatchRestTimerViewModel.loadTimerState] No active timer found", category: "WatchRestTimerViewModel")
                state = .selectDuration
            }
        }
    }
    
    func startTimer(duration: TimeInterval) async {
        AppLogger.debug("🔄 [WatchRestTimerViewModel.startTimer] Starting timer for \(duration)s", category: "WatchRestTimerViewModel")
        
        guard let dataManager = sharedDataManager else {
            AppLogger.error("❌ [WatchRestTimerViewModel.startTimer] SharedDataManager not available", category: "WatchRestTimerViewModel")
            return
        }
        
        do {
            let timerState = RestTimerState(
                isActive: true,
                duration: duration,
                remainingTime: duration,
                startTime: Date(),
                exerciseName: nil
            )
            
            try await dataManager.saveRestTimerState(timerState)
            
            // Provide haptic feedback
            WKInterfaceDevice.current().play(.start)
            
            state = .running(remainingTime: duration, totalDuration: duration)
            startTimerUpdates()
            
            AppLogger.debug("✅ [WatchRestTimerViewModel.startTimer] Timer started successfully", category: "WatchRestTimerViewModel")
        } catch {
            WKInterfaceDevice.current().play(.failure)
            AppLogger.error("❌ [WatchRestTimerViewModel.startTimer] Error: \(error.localizedDescription)", category: "WatchRestTimerViewModel", error: error)
        }
    }
    
    func pauseTimer() async {
        AppLogger.debug("🔄 [WatchRestTimerViewModel.pauseTimer] Pausing timer", category: "WatchRestTimerViewModel")
        
        guard case .running(let remainingTime, let totalDuration) = state,
              let dataManager = sharedDataManager else {
            AppLogger.error("❌ [WatchRestTimerViewModel.pauseTimer] No active timer or data manager", category: "WatchRestTimerViewModel")
            return
        }
        
        timer?.invalidate()
        timer = nil
        
        do {
            let pausedState = RestTimerState(
                isActive: false,
                duration: totalDuration,
                remainingTime: remainingTime,
                startTime: nil,
                exerciseName: nil
            )
            
            try await dataManager.saveRestTimerState(pausedState)
            
            // Provide haptic feedback
            WKInterfaceDevice.current().play(.click)
            
            state = .paused(remainingTime: remainingTime, totalDuration: totalDuration)
            
            AppLogger.debug("✅ [WatchRestTimerViewModel.pauseTimer] Timer paused successfully", category: "WatchRestTimerViewModel")
        } catch {
            AppLogger.error("❌ [WatchRestTimerViewModel.pauseTimer] Error: \(error.localizedDescription)", category: "WatchRestTimerViewModel", error: error)
        }
    }
    
    func resumeTimer() async {
        AppLogger.debug("🔄 [WatchRestTimerViewModel.resumeTimer] Resuming timer", category: "WatchRestTimerViewModel")
        
        guard case .paused(let remainingTime, let totalDuration) = state,
              let dataManager = sharedDataManager else {
            AppLogger.error("❌ [WatchRestTimerViewModel.resumeTimer] No paused timer or data manager", category: "WatchRestTimerViewModel")
            return
        }
        
        do {
            let resumedState = RestTimerState(
                isActive: true,
                duration: totalDuration,
                remainingTime: remainingTime,
                startTime: Date(),
                exerciseName: nil
            )
            
            try await dataManager.saveRestTimerState(resumedState)
            
            // Provide haptic feedback
            WKInterfaceDevice.current().play(.start)
            
            state = .running(remainingTime: remainingTime, totalDuration: totalDuration)
            startTimerUpdates()
            
            AppLogger.debug("✅ [WatchRestTimerViewModel.resumeTimer] Timer resumed successfully", category: "WatchRestTimerViewModel")
        } catch {
            WKInterfaceDevice.current().play(.failure)
            AppLogger.error("❌ [WatchRestTimerViewModel.resumeTimer] Error: \(error.localizedDescription)", category: "WatchRestTimerViewModel", error: error)
        }
    }
    
    func stopTimer() async {
        AppLogger.debug("🔄 [WatchRestTimerViewModel.stopTimer] Stopping timer", category: "WatchRestTimerViewModel")
        
        guard let dataManager = sharedDataManager else {
            AppLogger.error("❌ [WatchRestTimerViewModel.stopTimer] SharedDataManager not available", category: "WatchRestTimerViewModel")
            return
        }
        
        timer?.invalidate()
        timer = nil
        
        do {
            try await dataManager.clearRestTimerState()
            
            // Provide haptic feedback
            WKInterfaceDevice.current().play(.stop)
            
            state = .selectDuration
            
            AppLogger.debug("✅ [WatchRestTimerViewModel.stopTimer] Timer stopped successfully", category: "WatchRestTimerViewModel")
        } catch {
            AppLogger.error("❌ [WatchRestTimerViewModel.stopTimer] Error: \(error.localizedDescription)", category: "WatchRestTimerViewModel", error: error)
        }
    }
    
    func adjustTimer(by seconds: TimeInterval) async {
        AppLogger.debug("🔄 [WatchRestTimerViewModel.adjustTimer] Adjusting timer by \(seconds)s", category: "WatchRestTimerViewModel")
        
        guard case .running(let currentRemaining, let totalDuration) = state,
              let dataManager = sharedDataManager else {
            AppLogger.error("❌ [WatchRestTimerViewModel.adjustTimer] No active timer or data manager", category: "WatchRestTimerViewModel")
            return
        }
        
        let newRemaining = max(5, currentRemaining + seconds) // Minimum 5 seconds
        let newTotal = totalDuration + seconds
        
        do {
            let adjustedState = RestTimerState(
                isActive: true,
                duration: newTotal,
                remainingTime: newRemaining,
                startTime: Date().addingTimeInterval(-max(0, newTotal - newRemaining)),
                exerciseName: nil
            )
            
            try await dataManager.saveRestTimerState(adjustedState)
            
            // Provide haptic feedback
            WKInterfaceDevice.current().play(.click)
            
            state = .running(remainingTime: newRemaining, totalDuration: newTotal)
            
            AppLogger.debug("✅ [WatchRestTimerViewModel.adjustTimer] Timer adjusted successfully", category: "WatchRestTimerViewModel")
        } catch {
            AppLogger.error("❌ [WatchRestTimerViewModel.adjustTimer] Error: \(error.localizedDescription)", category: "WatchRestTimerViewModel", error: error)
        }
    }
    
    func resetTimer() {
        AppLogger.debug("🔄 [WatchRestTimerViewModel.resetTimer] Resetting timer", category: "WatchRestTimerViewModel")
        timer?.invalidate()
        timer = nil
        state = .selectDuration
    }
    
    // MARK: - Private Methods
    
    private func startTimerUpdates() {
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.updateTimer()
            }
        }
    }
    
    private func updateTimer() async {
        guard case .running(_, let totalDuration) = state,
              let dataManager = sharedDataManager else {
            return
        }
        
        // Get current timer state from shared storage
        if let timerState = await dataManager.getRestTimerState(),
           timerState.isActive,
           let startTime = timerState.startTime {
            
            let elapsed = Date().timeIntervalSince(startTime)
            let remaining = max(0, timerState.duration - elapsed)
            
            if remaining > 0 {
                state = .running(remainingTime: remaining, totalDuration: totalDuration)
                
                // Save updated state
                do {
                    let updatedState = RestTimerState(
                        isActive: true,
                        duration: timerState.duration,
                        remainingTime: remaining,
                        startTime: startTime,
                        exerciseName: timerState.exerciseName
                    )
                    try await dataManager.saveRestTimerState(updatedState)
                } catch {
                    AppLogger.error("❌ [WatchRestTimerViewModel.updateTimer] Error saving state: \(error.localizedDescription)", category: "WatchRestTimerViewModel", error: error)
                }
            } else {
                // Timer finished
                await timerFinished()
            }
        }
    }
    
    private func timerFinished() async {
        AppLogger.debug("🔄 [WatchRestTimerViewModel.timerFinished] Timer completed", category: "WatchRestTimerViewModel")
        
        timer?.invalidate()
        timer = nil
        
        // Clear timer state
        if let dataManager = sharedDataManager {
            do {
                try await dataManager.clearRestTimerState()
            } catch {
                AppLogger.error("❌ [WatchRestTimerViewModel.timerFinished] Error clearing state: \(error.localizedDescription)", category: "WatchRestTimerViewModel", error: error)
            }
        }
        
        // Provide completion haptic feedback and notification
        WKInterfaceDevice.current().play(.notification)
        
        // Show finished state
        state = .finished
        
        AppLogger.debug("✅ [WatchRestTimerViewModel.timerFinished] Timer finished successfully", category: "WatchRestTimerViewModel")
    }
}

// MARK: - State Management

enum WatchTimerState {
    case idle
    case loading
    case selectDuration
    case running(remainingTime: TimeInterval, totalDuration: TimeInterval)
    case paused(remainingTime: TimeInterval, totalDuration: TimeInterval)
    case finished
}

// MARK: - Previews

#Preview {
    WatchRestTimerView()
} 