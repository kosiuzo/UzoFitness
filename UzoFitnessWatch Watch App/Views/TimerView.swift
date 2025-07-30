import SwiftUI
import SwiftData
import WatchKit
import UzoFitnessCore

struct TimerView: View {
    @ObservedObject var viewModel: WatchTimerViewModel
    @State private var selectedPresetIndex = 1 // Default to 60 seconds
    
    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .idle:
                    IdleTimerView(
                        viewModel: viewModel,
                        selectedPresetIndex: $selectedPresetIndex
                    )
                    
                case .running(let timeRemaining, let exerciseName):
                    RunningTimerView(
                        timeRemaining: timeRemaining,
                        exerciseName: exerciseName,
                        viewModel: viewModel
                    )
                    
                case .paused(let timeRemaining, let exerciseName):
                    PausedTimerView(
                        timeRemaining: timeRemaining,
                        exerciseName: exerciseName,
                        viewModel: viewModel
                    )
                    
                case .completed(let exerciseName):
                    CompletedTimerView(
                        exerciseName: exerciseName,
                        viewModel: viewModel
                    )
                }
            }
            .navigationTitle("Timer")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Idle Timer View
struct IdleTimerView: View {
    let viewModel: WatchTimerViewModel
    @Binding var selectedPresetIndex: Int
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Rest Timer")
                .font(.title2)
                .fontWeight(.medium)
            
            // Quick Timer Buttons - Most Common Times
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    TimerQuickButton(duration: 60, label: "60s", viewModel: viewModel)
                    TimerQuickButton(duration: 90, label: "90s", viewModel: viewModel)
                }
                HStack(spacing: 12) {
                    TimerQuickButton(duration: 120, label: "2m", viewModel: viewModel)
                    TimerQuickButton(duration: 180, label: "3m", viewModel: viewModel)
                }
            }
        }
        .padding()
    }
}

// MARK: - Minimalist Timer Quick Button
struct TimerQuickButton: View {
    let duration: TimeInterval
    let label: String
    let viewModel: WatchTimerViewModel
    
    var body: some View {
        Button(label) {
            viewModel.quickStartTimer(duration: duration)
        }
        .buttonStyle(.borderedProminent)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Running Timer View
struct RunningTimerView: View {
    let timeRemaining: TimeInterval
    let exerciseName: String?
    let viewModel: WatchTimerViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Exercise Name (if provided)
                if let exerciseName = exerciseName {
                    Text(exerciseName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
                
                // Timer Display
                TimerDisplayView(
                    timeRemaining: timeRemaining,
                    progress: viewModel.progress,
                    formattedTime: viewModel.formattedTime
                )
                
                // Timer Controls
                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        Button {
                            viewModel.handle(.pauseTimer)
                        } label: {
                            Image(systemName: "pause.fill")
                                .font(.title2)
                        }
                        .buttonStyle(.bordered)
                        
                        Button {
                            viewModel.handle(.stopTimer)
                        } label: {
                            Image(systemName: "stop.fill")
                                .font(.title2)
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.red)
                    }
                    
                    // Quick Adjust Buttons
                    HStack(spacing: 12) {
                        Button("-30s") {
                            viewModel.handle(.subtractTime(seconds: 30))
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)
                        
                        Button("+30s") {
                            viewModel.handle(.addTime(seconds: 30))
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Paused Timer View
struct PausedTimerView: View {
    let timeRemaining: TimeInterval
    let exerciseName: String?
    let viewModel: WatchTimerViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Exercise Name (if provided)
                if let exerciseName = exerciseName {
                    Text(exerciseName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
                
                // Timer Display
                TimerDisplayView(
                    timeRemaining: timeRemaining,
                    progress: viewModel.progress,
                    formattedTime: viewModel.formattedTime
                )
                
                Text("Paused")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                // Timer Controls
                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        Button {
                            viewModel.handle(.resumeTimer)
                        } label: {
                            Image(systemName: "play.fill")
                                .font(.title2)
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button {
                            viewModel.handle(.stopTimer)
                        } label: {
                            Image(systemName: "stop.fill")
                                .font(.title2)
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.red)
                    }
                    
                    // Quick Adjust Buttons
                    HStack(spacing: 12) {
                        Button("-30s") {
                            viewModel.handle(.subtractTime(seconds: 30))
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)
                        
                        Button("+30s") {
                            viewModel.handle(.addTime(seconds: 30))
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Timer Display View
struct TimerDisplayView: View {
    let timeRemaining: TimeInterval
    let progress: Double
    let formattedTime: String
    
    var body: some View {
        ZStack {
            // Progress Ring
            Circle()
.stroke(Color.gray.opacity(0.3), lineWidth: 8)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.orange,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1), value: progress)
            
            // Time Display
            VStack(spacing: 4) {
                Text(formattedTime)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(.primary)
                
                Text("remaining")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 120, height: 120)
    }
}

// MARK: - Completed Timer View
struct CompletedTimerView: View {
    let exerciseName: String?
    let viewModel: WatchTimerViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Completion Animation
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.green)
                .scaleEffect(1.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: true)
            
            Text("Time's Up!")
                .font(.headline)
            
            if let exerciseName = exerciseName {
                Text("Rest complete for \(exerciseName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("Rest time complete")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Button("Start New Timer") {
                viewModel.handle(.stopTimer) // Reset to idle state
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .onAppear {
            // Trigger haptic feedback
            WKInterfaceDevice.current().play(.notification)
        }
    }
}

// MARK: - Removed connection status for minimalist design

#Preview {
    TimerView(viewModel: WatchTimerViewModel(
        syncCoordinator: SyncCoordinator.shared,
        sharedData: SharedDataManager.shared
    ))
}