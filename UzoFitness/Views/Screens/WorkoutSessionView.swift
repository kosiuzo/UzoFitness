import SwiftUI
import UzoFitnessCore

struct WorkoutSessionView: View {
    @ObservedObject var viewModel: LoggingViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationStack {
            contentView
                .navigationTitle("Workout Session")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            AppLogger.info("[WorkoutSessionView] Cancel button tapped", category: "WorkoutSessionView")
                            viewModel.handleIntent(.cancelSession)
                            isPresented = false
                        }
                    }
                }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        VStack(spacing: 0) {
            if !viewModel.exercises.isEmpty {
                // Exercise List
                ScrollView {
                    exerciseListSection
                }
                
                // Complete Workout Button (only show when all sets are completed)
                if viewModel.canFinishSession {
                    completeWorkoutButton
                }
            } else {
                // Loading or no exercises
                VStack(spacing: 24) {
                    SwiftUI.ProgressView("Loading workout...")
                        .font(.headline)
                    
                    Text("Preparing your exercises")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
            }
        }
        .background(Color(.systemGroupedBackground))
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
                                onBulkEditSets: { reps, weight in
                                    viewModel.handleIntent(.bulkEditSets(
                                        exerciseID: exercise.id,
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
                                getSupersetNumber: viewModel.getSupersetNumber,
                                isCurrentExercise: viewModel.currentExercise?.id == exercise.id
                            )
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
                            onBulkEditSets: { reps, weight in
                                viewModel.handleIntent(.bulkEditSets(
                                    exerciseID: exercise.id,
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
                            getSupersetNumber: viewModel.getSupersetNumber,
                            isCurrentExercise: viewModel.currentExercise?.id == exercise.id
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
                AppLogger.info("[WorkoutSessionView] Complete Workout button tapped", category: "WorkoutSessionView")
                viewModel.handleIntent(.finishSession)
                isPresented = false
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