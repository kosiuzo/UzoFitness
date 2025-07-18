import SwiftUI
import UzoFitnessCore

struct RestWorkoutCapsuleButton: View {
    let isRest: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 0) {
                // Rest option
                Text("Rest")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(isRest ? .white : .secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(isRest ? .blue : .clear)
                    .clipShape(Capsule())
                
                // Workout option
                Text("Workout")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(!isRest ? .white : .secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(!isRest ? .blue : .clear)
                    .clipShape(Capsule())
            }
            .background(.quaternary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
} 