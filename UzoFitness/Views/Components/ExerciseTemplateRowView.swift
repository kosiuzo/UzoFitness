import SwiftUI

struct ExerciseTemplateRowView: View {
    let exerciseTemplate: ExerciseTemplate
    
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
                            Text("\(weight, specifier: "%.1f") lbs")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Spacer(minLength: 8)
                
                // Superset badge positioned to avoid overlap with edit button
                if let supersetID = exerciseTemplate.supersetID,
                   let dayTemplate = exerciseTemplate.dayTemplate,
                   let supersetNumber = dayTemplate.getSupersetNumber(for: supersetID) {
                    Text("SS\(supersetNumber)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.blue)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 2)
    }
} 