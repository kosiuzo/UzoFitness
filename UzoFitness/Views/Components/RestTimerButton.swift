import SwiftUI
import SwiftData

struct RestTimerButton: View {
    @ObservedObject var viewModel: LoggingViewModel
    @State private var showingCustomDuration = false
    
    var body: some View {
        Button {
            if viewModel.globalRestTimerActive {
                viewModel.cancelGlobalRest()
            } else {
                showingCustomDuration = true
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: viewModel.globalRestTimerActive ? "timer" : "timer.circle")
                    .font(.title2)
                
                Text(viewModel.globalRestTimerActive ? 
                     formatTime(viewModel.globalRestTimer ?? 0) : 
                     "Rest Timer")
                    .font(.headline)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(viewModel.globalRestTimerActive ? Color.orange : Color.blue)
            .cornerRadius(12)
        }
        .sheet(isPresented: $showingCustomDuration) {
            RestTimerDurationPicker(viewModel: viewModel)
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    VStack(spacing: 20) {
        // Preview with inactive timer
        let container = try! ModelContainer(for: WorkoutSession.self)
        RestTimerButton(viewModel: LoggingViewModel(modelContext: ModelContext(container)))
            .padding()
        
        // Note: Cannot easily preview active state without mocking the viewModel
        Text("Active state shows orange background with countdown")
            .font(.caption)
            .foregroundColor(.secondary)
    }
}