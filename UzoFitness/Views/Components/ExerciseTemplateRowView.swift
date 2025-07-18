import SwiftUI
import UzoFitnessCore

struct ExerciseTemplateRowView: View {
    let exerciseTemplate: ExerciseTemplate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(exerciseTemplate.exercise.name)
                    .font(.headline)
                
                Spacer()
                
                if let supersetID = exerciseTemplate.supersetID,
                   let dayTemplate = exerciseTemplate.dayTemplate,
                   let supersetNumber = dayTemplate.getSupersetNumber(for: supersetID) {
                    Text("SS\(supersetNumber)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.blue)
                        .clipShape(Capsule())
                }
            }
            
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
        .padding(.vertical, 2)
    }
} 