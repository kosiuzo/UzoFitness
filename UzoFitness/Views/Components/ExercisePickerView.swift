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
            Group {
                if viewModel.exercises.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "dumbbell")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("Loading exercises...")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
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
        .onAppear {
            // Force a refresh of the exercises when the sheet appears
            AppLogger.debug("[ExercisePickerView.onAppear] Exercise count: \(viewModel.exercises.count)", category: "ExercisePickerView")
            viewModel.refreshExercisesForUI()
        }
    }
}