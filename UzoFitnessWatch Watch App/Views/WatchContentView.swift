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
                        
                        TestTabView()
                            .tabItem {
                                Image(systemName: WatchTab.test.systemImage)
                                Text(WatchTab.test.rawValue)
                            }
                            .tag(WatchTab.test)
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
                AppLogger.info("[WatchContentView] Creating WatchNavigationViewModel", category: "WatchUI")
                self.navigationViewModel = WatchNavigationViewModel(modelContext: modelContext)
                AppLogger.info("[WatchContentView] WatchNavigationViewModel created successfully", category: "WatchUI")
            }
        }
        .task {
            // Add a timeout to prevent infinite loading
            try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
            if let navViewModel = navigationViewModel, 
               case .loading = navViewModel.navigationState {
                AppLogger.warning("[WatchContentView] Initialization timeout - forcing ready state", category: "WatchUI")
                await MainActor.run {
                    navViewModel.forceReadyState()
                }
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

// MARK: - Tab Views
struct WorkoutTabView: View {
    @EnvironmentObject var navigationViewModel: WatchNavigationViewModel
    
    var body: some View {
        if let workoutViewModel = navigationViewModel.workoutViewModel {
            WorkoutView(viewModel: workoutViewModel)
        } else {
            VStack {
                ProgressView()
                Text("Loading workout...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
}

struct TimerTabView: View {
    @EnvironmentObject var navigationViewModel: WatchNavigationViewModel
    
    var body: some View {
        if let timerViewModel = navigationViewModel.timerViewModel {
            TimerView(viewModel: timerViewModel)
        } else {
            VStack {
                ProgressView()
                Text("Loading timer...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
}

struct ProgressTabView: View {
    @EnvironmentObject var navigationViewModel: WatchNavigationViewModel
    
    var body: some View {
        WatchProgressView()
            .environmentObject(navigationViewModel)
    }
}

struct TestTabView: View {
    @EnvironmentObject var navigationViewModel: WatchNavigationViewModel
    
    var body: some View {
        UserFlowTestView()
            .environmentObject(navigationViewModel)
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