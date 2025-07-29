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
        ScrollView {
            VStack(spacing: 16) {
                // Timer Icon
                Image(systemName: "timer")
                    .font(.system(size: 40))
                    .foregroundColor(.orange)
                
                Text("Rest Timer")
                    .font(.headline)
                
                // Connection Status
                ConnectionStatusView(isConnected: viewModel.isConnected)
                
                // Preset Selection
                VStack(spacing: 12) {
                    Text("Quick Start")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(Array(viewModel.timerPresets.enumerated()), id: \.offset) { index, duration in
                            TimerPresetButton(
                                duration: duration,
                                label: viewModel.getPresetLabel(for: duration),
                                isSelected: index == selectedPresetIndex,
                                action: {
                                    selectedPresetIndex = index
                                    viewModel.quickStartTimer(duration: duration)
                                }
                            )
                        }
                    }
                }
                
                // Custom Timer Button
                Button("Custom Timer") {
                    // For now, start with selected preset
                    let duration = viewModel.timerPresets[selectedPresetIndex]
                    viewModel.quickStartTimer(duration: duration)
                }
                .buttonStyle(.bordered)
                .font(.caption)
            }
            .padding()
        }
    }
}

// MARK: - Timer Preset Button
struct TimerPresetButton: View {
    let duration: TimeInterval
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("\(Int(duration))s")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.bordered)
        .background(isSelected ? Color.blue.opacity(0.2) : Color.clear)
        .cornerRadius(8)
    }
}

// MARK: - Running Timer View
struct RunningTimerView: View {
    let timeRemaining: TimeInterval
    let exerciseName: String?
    let viewModel: WatchTimerViewModel
    
    var body: some View {
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

// MARK: - Paused Timer View
struct PausedTimerView: View {
    let timeRemaining: TimeInterval
    let exerciseName: String?
    let viewModel: WatchTimerViewModel
    
    var body: some View {
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

// MARK: - Connection Status View
struct ConnectionStatusView: View {
    let isConnected: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isConnected ? .green : .red)
                .frame(width: 6, height: 6)
            
            Text(isConnected ? "Connected" : "Disconnected")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    TimerView(viewModel: WatchTimerViewModel(
        syncCoordinator: SyncCoordinator.shared,
        sharedData: SharedDataManager.shared
    ))
}