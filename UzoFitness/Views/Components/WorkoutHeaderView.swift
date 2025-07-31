import SwiftUI

struct WorkoutHeaderView: View {
    @Binding var workoutName: String
    @Binding var description: String
    
    var body: some View {
        VStack(spacing: 0) {
            TextField("Workout Name", text: $workoutName)
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            
            Divider()
                .padding(.horizontal, 16)
            
            TextField("Description", text: $description)
                .font(.body)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
} 