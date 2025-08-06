import SwiftUI

struct WorkoutStopwatchView: View {
    let elapsedTime: TimeInterval
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Workout Time")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(formatTime(elapsedTime))
                .font(.title2)
                .fontWeight(.bold)
                .monospacedDigit()
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    WorkoutStopwatchView(elapsedTime: 125) // 2:05
        .padding()
}