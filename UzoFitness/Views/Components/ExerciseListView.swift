import SwiftUI

struct ExerciseListView: View {
    let exerciseTemplates: [ExerciseTemplate]
    let onEditExercise: (ExerciseTemplate) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(exerciseTemplates.sorted(by: { $0.position < $1.position })) { exerciseTemplate in
                HStack(spacing: 0) {
                    ExerciseTemplateRowView(exerciseTemplate: exerciseTemplate)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Edit button positioned to avoid superset badge overlap
                    Button(action: { onEditExercise(exerciseTemplate) }) {
                        Image(systemName: "pencil")
                            .foregroundStyle(.blue)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding(.trailing, 16)
                }
                .background(Color(.systemBackground))
                .onTapGesture {
                    onEditExercise(exerciseTemplate)
                }
                
                if exerciseTemplate.id != exerciseTemplates.sorted(by: { $0.position < $1.position }).last?.id {
                    Divider()
                        .padding(.horizontal, 16)
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
} 