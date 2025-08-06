import SwiftUI
import SwiftData

struct RestTimerDurationPicker: View {
    @ObservedObject var viewModel: LoggingViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedDuration: TimeInterval = 60
    private let durationOptions: [TimeInterval] = [30, 45, 60, 90, 120, 180]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Select Rest Duration")
                    .font(.title2)
                    .fontWeight(.bold)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    ForEach(durationOptions, id: \.self) { duration in
                        Button {
                            selectedDuration = duration
                        } label: {
                            VStack(spacing: 8) {
                                Text(formatTime(duration))
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                
                                Text("seconds")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(selectedDuration == duration ? Color.blue : Color(.systemGray5))
                            .foregroundColor(selectedDuration == duration ? .white : .primary)
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Spacer()
                
                Button {
                    viewModel.startGlobalRest(seconds: selectedDuration)
                    dismiss()
                } label: {
                    Text("Start Rest Timer")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
            .padding(24)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            return "\(Int(timeInterval))s"
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: WorkoutSession.self)
    RestTimerDurationPicker(viewModel: LoggingViewModel(modelContext: ModelContext(container)))
}