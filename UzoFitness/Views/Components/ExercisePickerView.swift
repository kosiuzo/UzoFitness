import SwiftUI

struct ExercisePickerView: View {
    let onSelection: ([Exercise]) -> Void
    @ObservedObject var viewModel: LibraryViewModel
    @State private var selectedExercises: Set<Exercise> = []
    @Environment(\.dismiss) private var dismiss
    
    init(viewModel: LibraryViewModel, onSelection: @escaping ([Exercise]) -> Void) {
        self.viewModel = viewModel
        self.onSelection = onSelection
    }
    
    var body: some View {
        NavigationView {
            List(viewModel.exercises) { exercise in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exercise.name)
                            .font(.headline)
                        
                        Text(exercise.category.rawValue.capitalized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if selectedExercises.contains(exercise) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.blue)
                    } else {
                        Image(systemName: "circle")
                            .foregroundStyle(.gray)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if selectedExercises.contains(exercise) {
                        selectedExercises.remove(exercise)
                    } else {
                        selectedExercises.insert(exercise)
                    }
                }
            }
            .navigationTitle("Select Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add (\(selectedExercises.count))") {
                        onSelection(Array(selectedExercises))
                        dismiss()
                    }
                    .disabled(selectedExercises.isEmpty)
                }
            }
        }
    }
} 