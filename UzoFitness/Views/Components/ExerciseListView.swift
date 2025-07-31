import SwiftUI

struct ExerciseListView: View {
    let exerciseTemplates: [ExerciseTemplate]
    let onEditExercise: (ExerciseTemplate) -> Void
    let onDeleteExercise: ((ExerciseTemplate) -> Void)?
    let onReorderExercises: ((IndexSet, Int) -> Void)?
    
    init(
        exerciseTemplates: [ExerciseTemplate],
        onEditExercise: @escaping (ExerciseTemplate) -> Void,
        onDeleteExercise: ((ExerciseTemplate) -> Void)? = nil,
        onReorderExercises: ((IndexSet, Int) -> Void)? = nil
    ) {
        self.exerciseTemplates = exerciseTemplates
        self.onEditExercise = onEditExercise
        self.onDeleteExercise = onDeleteExercise
        self.onReorderExercises = onReorderExercises
    }
    
    private var sortedExercises: [ExerciseTemplate] {
        exerciseTemplates.sorted(by: { $0.position < $1.position })
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(sortedExercises) { exerciseTemplate in
                ExerciseTemplateRowView(
                    exerciseTemplate: exerciseTemplate,
                    onEditExercise: onEditExercise
                )
                .background(Color(.systemBackground))
                .onTapGesture {
                    onEditExercise(exerciseTemplate)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                
                if exerciseTemplate != sortedExercises.last {
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