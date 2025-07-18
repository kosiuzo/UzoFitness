import SwiftUI
import UzoFitnessCore

struct ExerciseDetailCard: View {
    let sessionExercise: SessionExercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Exercise Name and Volume
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(sessionExercise.exercise.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if sessionExercise.totalVolume > 0 {
                        Text("Volume: \(formatVolume(sessionExercise.totalVolume))")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                if sessionExercise.completedSets.isEmpty {
                    Text("Not Completed")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .foregroundColor(.orange)
                        .cornerRadius(6)
                }
            }
            
            // Sets List
            if !sessionExercise.completedSets.isEmpty {
                VStack(spacing: 8) {
                    // Headers
                    HStack {
                        Text("Set")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .frame(width: 40, alignment: .leading)
                        
                        Text("Reps")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .frame(width: 60, alignment: .leading)
                        
                        Text("Weight")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .frame(width: 80, alignment: .leading)
                        
                        Text("Volume")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(.horizontal, 12)
                    
                    // Set Rows
                    ForEach(sessionExercise.completedSets.sorted(by: { $0.position < $1.position }), id: \.id) { completedSet in
                        HistorySetRowView(
                            setNumber: completedSet.position + 1,
                            completedSet: completedSet
                        )
                    }
                }
                .padding(.vertical, 8)
                .background(.regularMaterial)
                .cornerRadius(8)
            }
        }
        .padding(16)
        .background(.thickMaterial)
        .cornerRadius(12)
    }
    
    private func formatVolume(_ volume: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return (formatter.string(from: NSNumber(value: volume)) ?? "0") + " lbs"
    }
} 