import SwiftUI
import SwiftData
import UzoFitnessCore

struct WatchContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var navigationViewModel: WatchNavigationViewModel?
    
    var body: some View {
        Group {
            if let navigationViewModel = navigationViewModel {
                switch navigationViewModel.navigationState {
                case .loading:
                    LoadingView()
                    
                case .ready:
                    TabView(selection: Binding(
                        get: { navigationViewModel.selectedTab },
                        set: { navigationViewModel.selectTab($0) }
                    )) {
                        WorkoutTabView()
                            .tabItem {
                                Image(systemName: WatchTab.workout.systemImage)
                                Text(WatchTab.workout.rawValue)
                            }
                            .tag(WatchTab.workout)
                            .environmentObject(navigationViewModel)
                        
                        TimerTabView()
                            .tabItem {
                                Image(systemName: WatchTab.timer.systemImage)
                                Text(WatchTab.timer.rawValue)
                            }
                            .tag(WatchTab.timer)
                            .environmentObject(navigationViewModel)
                        
                        ProgressTabView()
                            .tabItem {
                                Image(systemName: WatchTab.progress.systemImage)
                                Text(WatchTab.progress.rawValue)
                            }
                            .tag(WatchTab.progress)
                            .environmentObject(navigationViewModel)
                    }
                    .tabViewStyle(.page)
                    
                case .error(let message):
                    ErrorView(message: message) {
                        navigationViewModel.retryAfterError()
                    }
                }
            } else {
                LoadingView()
            }
        }
        .onAppear {
            if navigationViewModel == nil {
                self.navigationViewModel = WatchNavigationViewModel(modelContext: modelContext)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: WKExtension.applicationWillEnterForegroundNotification)) { _ in
            navigationViewModel?.handleAppWillEnterForeground()
        }
        .onReceive(NotificationCenter.default.publisher(for: WKExtension.applicationDidEnterBackgroundNotification)) { _ in
            navigationViewModel?.handleAppDidEnterBackground()
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("UzoFitness")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Loading...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

// MARK: - Error View
struct ErrorView: View {
    let message: String
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text("Error")
                .font(.headline)
            
            Text(message)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Retry", action: retry)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Tab Views (Placeholders)
struct WorkoutTabView: View {
    @EnvironmentObject var navigationViewModel: WatchNavigationViewModel
    
    var body: some View {
        VStack {
            if navigationViewModel.workoutViewModel != nil {
                // Workout view will be implemented in Milestone 3
                Text("Workout")
                    .font(.headline)
                Text("Ready for your workout!")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Loading workout...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

struct TimerTabView: View {
    @EnvironmentObject var navigationViewModel: WatchNavigationViewModel
    
    var body: some View {
        VStack {
            if navigationViewModel.timerViewModel != nil {
                // Timer view will be implemented in Milestone 3
                Text("Timer")
                    .font(.headline)
                Text("Rest between sets")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Loading timer...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

struct ProgressTabView: View {
    @EnvironmentObject var navigationViewModel: WatchNavigationViewModel
    
    var body: some View {
        VStack {
            Text("Progress")
                .font(.headline)
            
            Text("View your stats")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Connection status
            HStack {
                Circle()
                    .fill(navigationViewModel.isConnectedToPhone ? .green : .red)
                    .frame(width: 8, height: 8)
                
                Text(navigationViewModel.connectionStatusText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 8)
        }
        .padding()
    }
}

// MARK: - Preview Extension for ModelContext
extension ModelContext {
    static let preview: ModelContext = {
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(
                for: WorkoutPlan.self,
                configurations: config
            )
            return ModelContext(container)
        } catch {
            fatalError("Failed to create preview context: \(error)")
        }
    }()
}

#Preview {
    WatchContentView()
}