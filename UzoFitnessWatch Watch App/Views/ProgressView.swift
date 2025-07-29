import SwiftUI
import SwiftData
import WatchKit
import UzoFitnessCore

struct WatchProgressView: View {
    @EnvironmentObject var navigationViewModel: WatchNavigationViewModel
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // App Status
                    AppStatusCard(navigationViewModel: navigationViewModel)
                    
                    // Workout Progress
                    if let workoutProgress = navigationViewModel.workoutViewModel?.workoutProgress {
                        WorkoutProgressCard(progress: workoutProgress)
                    }
                    
                    // Timer Status
                    if let timerViewModel = navigationViewModel.timerViewModel {
                        TimerStatusCard(timerViewModel: timerViewModel)
                    }
                    
                    // Sync Information
                    SyncStatusCard(navigationViewModel: navigationViewModel)
                    
                    // Quick Actions
                    QuickActionsCard(navigationViewModel: navigationViewModel)
                }
                .padding(.horizontal, 8)
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - App Status Card
struct AppStatusCard: View {
    let navigationViewModel: WatchNavigationViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "applewatch.watchface")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("UzoFitness Watch")
                        .font(.headline)
                    
                    Text(statusText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                StatusIndicator(isReady: navigationViewModel.isAppReady)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var statusText: String {
        if navigationViewModel.isAppReady {
            return "Ready"
        } else if case .loading = navigationViewModel.navigationState {
            return "Loading..."
        } else if case .error(let message) = navigationViewModel.navigationState {
            return "Error: \(message)"
        } else {
            return "Starting up..."
        }
    }
}

// MARK: - Workout Progress Card
struct WorkoutProgressCard: View {
    let progress: SharedWorkoutProgress
    
    private var completionPercentage: Double {
        guard progress.totalSets > 0 else { return 0 }
        return Double(progress.completedSets) / Double(progress.totalSets)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.title2)
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Current Workout")
                        .font(.headline)
                    
                    Text("Session in progress")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            VStack(spacing: 8) {
                // Sets Progress
                HStack {
                    Text("Sets")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(progress.completedSets)/\(progress.totalSets)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                ProgressView(value: completionPercentage)
                    .progressViewStyle(LinearProgressViewStyle(tint: .green))
                
                // Exercises Progress
                HStack {
                    Text("Exercises")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(progress.completedExercises)/\(progress.totalExercises)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                let exerciseProgress = progress.totalExercises > 0 ? 
                    Double(progress.completedExercises) / Double(progress.totalExercises) : 0
                
                ProgressView(value: exerciseProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                
                // Estimated Time Remaining
                if let timeRemaining = progress.estimatedTimeRemaining {
                    HStack {
                        Text("Est. time remaining")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(formatTimeInterval(timeRemaining))
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Timer Status Card
struct TimerStatusCard: View {
    @ObservedObject var timerViewModel: WatchTimerViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "timer")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Rest Timer")
                        .font(.headline)
                    
                    Text(timerStatusText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if case .running = timerViewModel.state {
                    Text(timerViewModel.formattedTime)
                        .font(.system(.caption, design: .monospaced))
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                }
            }
            
            // Quick timer controls when running/paused
            if case .running = timerViewModel.state {
                HStack(spacing: 8) {
                    Button {
                        timerViewModel.handle(.pauseTimer)
                    } label: {
                        Image(systemName: "pause.fill")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                    
                    Button {
                        timerViewModel.handle(.stopTimer)
                    } label: {
                        Image(systemName: "stop.fill")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                    .foregroundColor(.red)
                }
            } else if case .paused = timerViewModel.state {
                HStack(spacing: 8) {
                    Button {
                        timerViewModel.handle(.resumeTimer)
                    } label: {
                        Image(systemName: "play.fill")
                            .font(.caption)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.mini)
                    
                    Button {
                        timerViewModel.handle(.stopTimer)
                    } label: {
                        Image(systemName: "stop.fill")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                    .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var timerStatusText: String {
        switch timerViewModel.state {
        case .idle:
            return "Ready to start"
        case .running(_, let exerciseName):
            return exerciseName ?? "Running"
        case .paused(_, let exerciseName):
            return "Paused - \(exerciseName ?? "Timer")"
        case .completed(let exerciseName):
            return "Completed - \(exerciseName ?? "Timer")"
        }
    }
}

// MARK: - Sync Status Card
struct SyncStatusCard: View {
    let navigationViewModel: WatchNavigationViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: navigationViewModel.isConnectedToPhone ? "iphone.and.apple.watch" : "iphone.slash")
                    .font(.title2)
                    .foregroundColor(navigationViewModel.isConnectedToPhone ? .green : .red)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Phone Connection")
                        .font(.headline)
                    
                    Text(navigationViewModel.connectionStatusText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                StatusIndicator(isReady: navigationViewModel.isConnectedToPhone)
            }
            
            if !navigationViewModel.isConnectedToPhone {
                Button("Retry Connection") {
                    navigationViewModel.retryConnection()
                }
                .buttonStyle(.bordered)
                .font(.caption)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Quick Actions Card
struct QuickActionsCard: View {
    let navigationViewModel: WatchNavigationViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
            
            VStack(spacing: 8) {
                Button("Check Today's Workout") {
                    navigationViewModel.selectTab(.workout)
                    navigationViewModel.workoutViewModel?.handle(.startTodaysWorkout)
                }
                .buttonStyle(.bordered)
                .font(.caption)
                
                Button("Start 90s Rest Timer") {
                    navigationViewModel.selectTab(.timer)
                    navigationViewModel.timerViewModel?.quickStartTimer(duration: 90)
                }
                .buttonStyle(.bordered)
                .font(.caption)
                
                if !navigationViewModel.isConnectedToPhone {
                    Button("Sync with Phone") {
                        navigationViewModel.retryConnection()
                    }
                    .buttonStyle(.borderedProminent)
                    .font(.caption)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Status Indicator
struct StatusIndicator: View {
    let isReady: Bool
    
    var body: some View {
        Circle()
            .fill(isReady ? .green : .red)
            .frame(width: 8, height: 8)
    }
}

#Preview {
    WatchProgressView()
        .environmentObject(WatchNavigationViewModel(modelContext: ModelContext.preview))
}