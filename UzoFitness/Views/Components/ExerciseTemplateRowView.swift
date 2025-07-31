import SwiftUI

struct ExerciseTemplateRowView: View {
    let exerciseTemplate: ExerciseTemplate
    let onEditExercise: (ExerciseTemplate) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exerciseTemplate.exercise.name)
                        .font(.headline)
                        .lineLimit(2)
                    
                    HStack(spacing: 16) {
                        Text("\(exerciseTemplate.setCount) sets")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text("\(exerciseTemplate.reps) reps")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if let weight = exerciseTemplate.weight {
                            Text("\(weight, specifier: "%.1f") kg")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Spacer(minLength: 12)
                
                // Superset badge if exercise is part of a superset
                if let supersetID = exerciseTemplate.supersetID,
                   let dayTemplate = exerciseTemplate.dayTemplate,
                   let supersetNumber = dayTemplate.getSupersetNumber(for: supersetID) {
                    SupersetBadgeView(supersetNumber: supersetNumber, isHead: true)
                }
                
                // Edit button
                Button(action: { onEditExercise(exerciseTemplate) }) {
                    Image(systemName: "pencil")
                        .foregroundStyle(.blue)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .frame(height: 60) // Fixed height for consistent row sizing
    }
} 