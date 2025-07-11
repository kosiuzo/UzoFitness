import SwiftUI
import SwiftData

struct WorkoutSessionView: View {
    @ObservedObject var viewModel: LoggingViewModel
    @State private var initialFocus: SetRowView.Field? = nil
    @State private var isAnySetEditing: Bool = false
    @State private var editingExerciseID: UUID? = nil
    @State private var editingSetIndex: Int? = nil
    @State private var tempReps: String = ""
    @State private var tempWeight: String = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Exercise List
            ScrollView {
                exerciseListSection
            }
            
            // Complete Workout Button
            if viewModel.canFinishSession {
                completeWorkoutButton
            }
        }
        .background(.background.secondary)
        .navigationTitle("Workout Session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("End Session") {
                    dismiss()
                }
                .foregroundColor(.red)
            }
            
            if isAnySetEditing {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        saveCurrentSet()
                    }
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                }
            }
        }
    }
    
    private func saveCurrentSet() {
        guard let exerciseID = editingExerciseID,
              let setIndex = editingSetIndex,
              let reps = Int(tempReps),
              let weight = Double(tempWeight) else { return }
        
        viewModel.handleIntent(.editSet(
            exerciseID: exerciseID,
            setIndex: setIndex,
            reps: reps,
            weight: weight
        ))
        
        // Reset editing state
        isAnySetEditing = false
        editingExerciseID = nil
        editingSetIndex = nil
        tempReps = ""
        tempWeight = ""
    }
    
    // MARK: - Exercise List Section
    private var exerciseListSection: some View {
        LazyVStack(spacing: 16) {
            ForEach(viewModel.groupedExercises, id: \.1.first?.id) { group in
                if group.0 != nil {
                    // Superset group with minimal visual separation
                    VStack(spacing: 12) {
                        ForEach(group.1) { exercise in
                            LoggingExerciseRowView(
                                exercise: exercise,
                                onEditSet: { setIndex, reps, weight in
                                    viewModel.handleIntent(.editSet(
                                        exerciseID: exercise.id,
                                        setIndex: setIndex,
                                        reps: reps,
                                        weight: weight
                                    ))
                                },
                                onAddSet: {
                                    viewModel.handleIntent(.addSet(exerciseID: exercise.id))
                                },
                                onToggleSetCompletion: { setIndex in
                                    viewModel.handleIntent(.toggleSetCompletion(
                                        exerciseID: exercise.id,
                                        setIndex: setIndex
                                    ))
                                },
                                onMarkComplete: {
                                    viewModel.handleIntent(.markExerciseComplete(exerciseID: exercise.id))
                                },
                                onUseLastValues: {
                                    viewModel.handleIntent(.useLastValues(exerciseID: exercise.id))
                                },
                                getSupersetNumber: viewModel.getSupersetNumber,
                                isCurrentExercise: viewModel.currentExercise?.id == exercise.id,
                                initialFocus: $initialFocus,
                                isAnySetEditing: $isAnySetEditing,
                                editingExerciseID: $editingExerciseID,
                                editingSetIndex: $editingSetIndex,
                                tempReps: $tempReps,
                                tempWeight: $tempWeight
                            )
                            .background(Color(.systemGray6).opacity(0.3))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.vertical, 8)
                } else {
                    // Individual exercises
                    ForEach(group.1) { exercise in
                        LoggingExerciseRowView(
                            exercise: exercise,
                            onEditSet: { setIndex, reps, weight in
                                viewModel.handleIntent(.editSet(
                                    exerciseID: exercise.id,
                                    setIndex: setIndex,
                                    reps: reps,
                                    weight: weight
                                ))
                            },
                            onAddSet: {
                                viewModel.handleIntent(.addSet(exerciseID: exercise.id))
                            },
                            onToggleSetCompletion: { setIndex in
                                viewModel.handleIntent(.toggleSetCompletion(
                                    exerciseID: exercise.id,
                                    setIndex: setIndex
                                ))
                            },
                            onMarkComplete: {
                                viewModel.handleIntent(.markExerciseComplete(exerciseID: exercise.id))
                            },
                            onUseLastValues: {
                                viewModel.handleIntent(.useLastValues(exerciseID: exercise.id))
                            },
                            getSupersetNumber: viewModel.getSupersetNumber,
                            isCurrentExercise: viewModel.currentExercise?.id == exercise.id,
                            initialFocus: $initialFocus,
                            isAnySetEditing: $isAnySetEditing,
                            editingExerciseID: $editingExerciseID,
                            editingSetIndex: $editingSetIndex,
                            tempReps: $tempReps,
                            tempWeight: $tempWeight
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Complete Workout Button
    private var completeWorkoutButton: some View {
        VStack(spacing: 0) {
            Divider()
            
            Button {
                AppLogger.info("[WorkoutSessionView] Complete Workout button tapped", category: "WorkoutSession")
                viewModel.handleIntent(.finishSession)
                dismiss()
            } label: {
                Text("Complete Workout")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(viewModel.canFinishSession ? Color.blue : Color.gray)
                    .cornerRadius(12)
            }
            .disabled(!viewModel.canFinishSession)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.background)
        }
    }
}