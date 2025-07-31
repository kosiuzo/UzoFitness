import SwiftUI

struct AddExerciseButton: View {
    let onAddExercise: () -> Void
    
    var body: some View {
        Button(action: onAddExercise) {
            Text("Add Exercise")
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
        }
    }
} 