import SwiftUI
import SwiftData
import UzoFitnessCore
import WatchKit

struct UserFlowTestView: View {
    @StateObject private var flowCoordinator: UserFlowCoordinator
    @EnvironmentObject var navigationViewModel: WatchNavigationViewModel
    
    init() {
        self._flowCoordinator = StateObject(wrappedValue: UserFlowCoordinator(
            syncCoordinator: SyncCoordinator.shared,
            navigationViewModel: WatchNavigationViewModel(modelContext: ModelContext.previewNavigation)
        ))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // Current Flow Status
                    if let currentFlow = flowCoordinator.currentFlow {
                        CurrentFlowCard(
                            flow: currentFlow,
                            state: flowCoordinator.flowState,
                            progress: flowCoordinator.flowProgress,
                            message: flowCoordinator.flowMessage
                        )
                    }
                    
                    // Flow Test Buttons
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        FlowTestButton(
                            title: "App Launch",
                            icon: "power",
                            color: .blue,
                            flow: .appLaunch,
                            coordinator: flowCoordinator
                        )
                        
                        FlowTestButton(
                            title: "Workout Start",
                            icon: "play.fill",
                            color: .green,
                            flow: .workoutStart,
                            coordinator: flowCoordinator
                        )
                        
                        FlowTestButton(
                            title: "Workout Execution",
                            icon: "figure.strengthtraining.traditional",
                            color: .orange,
                            flow: .workoutExecution,
                            coordinator: flowCoordinator
                        )
                        
                        FlowTestButton(
                            title: "Set Completion",
                            icon: "checkmark.circle",
                            color: .green,
                            flow: .setCompletion,
                            coordinator: flowCoordinator
                        )
                        
                        FlowTestButton(
                            title: "Timer Management",
                            icon: "timer",
                            color: .orange,
                            flow: .timerManagement,
                            coordinator: flowCoordinator
                        )
                        
                        FlowTestButton(
                            title: "Workout Complete",
                            icon: "flag.checkered",
                            color: .purple,
                            flow: .workoutCompletion,
                            coordinator: flowCoordinator
                        )
                        
                        FlowTestButton(
                            title: "Error Recovery",
                            icon: "exclamationmark.triangle",
                            color: .red,
                            flow: .errorRecovery,
                            coordinator: flowCoordinator
                        )
                        
                        FlowTestButton(
                            title: "Connectivity Test",
                            icon: "antenna.radiowaves.left.and.right",
                            color: .blue,
                            flow: .connectivityTesting,
                            coordinator: flowCoordinator
                        )
                    }
                    
                    // Quick Actions
                    QuickActionsSection(flowCoordinator: flowCoordinator)
                }
                .padding(.horizontal, 8)
            }
            .navigationTitle("Flow Tests")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            flowCoordinator.startFlow(.appLaunch)
        }
    }
}

// MARK: - Current Flow Card
struct CurrentFlowCard: View {
    let flow: UserFlow
    let state: FlowState
    let progress: Double
    let message: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: stateIcon)
                    .font(.title2)
                    .foregroundColor(stateColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(flow.description)
                        .font(.headline)
                    
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            
            if case .inProgress = state {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: stateColor))
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var stateIcon: String {
        switch state {
        case .idle:
            return "circle"
        case .inProgress:
            return "circle.dotted"
        case .completed:
            return "checkmark.circle.fill"
        case .error:
            return "exclamationmark.circle.fill"
        }
    }
    
    private var stateColor: Color {
        switch state {
        case .idle:
            return .gray
        case .inProgress:
            return .blue
        case .completed:
            return .green
        case .error:
            return .red
        }
    }
}

// MARK: - Flow Test Button
struct FlowTestButton: View {
    let title: String
    let icon: String
    let color: Color
    let flow: UserFlow
    let coordinator: UserFlowCoordinator
    
    @State private var isPressed = false
    
    var body: some View {
        Button {
            coordinator.startFlow(flow)
            
            // Haptic feedback
            WKInterfaceDevice.current().play(.click)
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(height: 60)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(isPressed ? 0.3 : 0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0.0, maximumDistance: .infinity, perform: {}, onPressingChanged: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        })
        .disabled(coordinator.flowState == .inProgress)
    }
}

// MARK: - Quick Actions Section
struct QuickActionsSection: View {
    let flowCoordinator: UserFlowCoordinator
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Quick Actions")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 8) {
                Button("Test Connection") {
                    SyncCoordinator.shared.sendTestMessage()
                    WKInterfaceDevice.current().play(.click)
                }
                .buttonStyle(.bordered)
                .font(.caption)
                .controlSize(.small)
                
                Button("Send Heartbeat") {
                    SyncCoordinator.shared.sendHeartbeat()
                    WKInterfaceDevice.current().play(.click)
                }
                .buttonStyle(.bordered)
                .font(.caption)
                .controlSize(.small)
            }
            
            HStack(spacing: 8) {
                Button("Clear Pending") {
                    SyncCoordinator.shared.clearPendingOperations()
                    WKInterfaceDevice.current().play(.click)
                }
                .buttonStyle(.bordered)
                .font(.caption)
                .controlSize(.small)
                
                Button("Validate Connection") {
                    let isValid = SyncCoordinator.shared.validateConnection()
                    AppLogger.info("Connection valid: \(isValid)", category: "UserFlow")
                    WKInterfaceDevice.current().play(isValid ? .success : .failure)
                }
                .buttonStyle(.bordered)
                .font(.caption)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Preview
#Preview {
    UserFlowTestView()
        .environmentObject(WatchNavigationViewModel(modelContext: ModelContext.previewNavigation))
}