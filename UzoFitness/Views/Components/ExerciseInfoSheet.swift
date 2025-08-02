import SwiftUI

// MARK: - Exercise Info Sheet
struct ExerciseInfoSheet: View {
    let exercise: Exercise
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(exercise.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(exercise.category.rawValue.capitalized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.blue.opacity(0.1))
                            )
                    }
                    .padding(.horizontal, 20)
                    
                    // Instructions Section
                    if !exercise.instructions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "text.book.closed")
                                    .foregroundColor(.blue)
                                Text("Instructions")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            
                            Text(exercise.instructions)
                                .font(.body)
                                .foregroundColor(.primary)
                                .lineSpacing(4)
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Media Section (if available)
                    if exercise.mediaAssetID != nil {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "video")
                                    .foregroundColor(.blue)
                                Text("Demo")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            
                            // Placeholder for media content
                            // In a real implementation, you would load and display the media here
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray5))
                                .frame(height: 200)
                                .overlay(
                                    VStack(spacing: 8) {
                                        Image(systemName: "play.circle.fill")
                                            .font(.system(size: 48))
                                            .foregroundColor(.blue)
                                        Text("Exercise Demo")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                )
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // No content message
                    if exercise.instructions.isEmpty && exercise.mediaAssetID == nil {
                        VStack(spacing: 16) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            
                            Text("No additional information available")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("Instructions and media content can be added to exercises in the library.")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                }
                .padding(.vertical, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ExerciseInfoSheet(exercise: Exercise(
        name: "Bench Press",
        category: .strength,
        instructions: "Lie on a flat bench with your feet flat on the ground. Grip the barbell slightly wider than shoulder width. Lower the bar to your chest, then press it back up to the starting position. Keep your core tight and maintain proper form throughout the movement."
    ))
} 