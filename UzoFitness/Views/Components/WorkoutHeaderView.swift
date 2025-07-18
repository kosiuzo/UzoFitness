import SwiftUI
import UzoFitnessCore

struct WorkoutHeaderView: View {
    let date: Date
    let duration: TimeInterval?
    let totalVolume: Double
    let exerciseCount: Int
    let totalSets: Int
    
    var body: some View {
        VStack(spacing: 12) {
            // Date and Duration (stacked vertically)
            VStack(alignment: .leading, spacing: 4) {
                Text(DateFormatter.fullDate.string(from: date))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let duration = duration {
                    Text("Duration: \(formatDuration(duration))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Stats Row
            HStack(spacing: 24) {
                StatView(
                    title: "Total Volume",
                    value: formatVolume(totalVolume),
                    color: .blue
                )
                StatView(
                    title: "Exercises",
                    value: "\(exerciseCount)",
                    color: .green
                )
                if exerciseCount > 0 {
                    StatView(
                        title: "Sets",
                        value: "\(totalSets)",
                        color: .orange
                    )
                }
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func formatVolume(_ volume: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return (formatter.string(from: NSNumber(value: volume)) ?? "0") + " lbs"
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
} 