import SwiftUI

struct CurrentExerciseHeaderView: View {
    let currentExercise: SessionExerciseUI?
    let totalExercises: Int
    let currentIndex: Int
    let isWorkoutInProgress: Bool
    let getSupersetNumber: (UUID) -> Int?
    
    var body: some View {
        VStack(spacing: 8) {
            // Exercise name with compact spacing
            VStack(spacing: 4) {
                Text(currentExercise?.name ?? "No Exercise")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("\(currentIndex + 1) of \(totalExercises)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Subtle superset indicator (if applicable)
            if let supersetID = currentExercise?.supersetID,
               let supersetNumber = getSupersetNumber(supersetID) {
                SupersetBadgeView(
                    supersetNumber: supersetNumber,
                    isHead: currentExercise?.isSupersetHead ?? false
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    VStack(spacing: 20) {
        CurrentExerciseHeaderView(
            currentExercise: nil,
            totalExercises: 5,
            currentIndex: 0,
            isWorkoutInProgress: false,
            getSupersetNumber: { _ in nil }
        )
        
        // Preview with a mock exercise (would need actual SessionExerciseUI for real preview)
        CurrentExerciseHeaderView(
            currentExercise: nil,
            totalExercises: 5,
            currentIndex: 2,
            isWorkoutInProgress: true,
            getSupersetNumber: { _ in 1 }
        )
    }
    .padding()
}